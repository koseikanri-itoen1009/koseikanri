CREATE OR REPLACE PACKAGE BODY XXCOK023A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A01C(body)
 * Description      : 運送費予算算出
 * MD.050           : 運送費予算算出 MD050_COK_023_A01
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_budget_year        予算年度抽出処理(A-2)
 *  get_item_plan_info     商品計画テーブル情報抽出処理(A-3)
 *  get_item_info          品目マスタ情報抽出処理(A-4)
 *  sum_cs_qty             数量(C/S)算出処理(A-5)
 *  get_cust_mst_info      顧客マスタ情報抽出処理(A-6)
 *  get_drink_dlv_cost     ドリンク振替運賃アドオンマスタ情報抽出処理(A-7)
 *  sum_dlv_cost_budget    運送費予算金額算出処理(A-8)
 *  set_dlv_cost_budget    運送費予算テーブル登録項目のPL/SQL表格納処理(A-9)
 *  delete_dlv_cost_budget 運送費予算テーブル削除処理(A-10)
 *  insert_dlv_cost_budget 運送費予算テーブル登録処理(A-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   A.Yano           新規作成
 *  2008/12/11    1.1   A.Yano           例外処理部修正
 *  2008/12/19    1.2   A.Yano           例外処理部修正
 *  2008/12/22    1.3   A.Yano           メッセージ出力、ログ出力修正
 *  2009/03/25    1.4   A.Yano           [障害T1_0064] オープン年度を取得する条件追加
 *  2009/05/12    1.5   A.Yano           [障害T1_0772] 設定単価エラーメッセージに品目コード追加
 *  2009/09/03    1.6   S.Moriyama       [障害0001257] OPM品目マスタ取得条件追加
 *  2010/07/09    1.7   H.Sasaki         [E_本稼動_03494] ドリンク振替運賃アドオンの有効チェック修正
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
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
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK023A01C';
  -- アプリケーション短縮名
  cv_app_short_name_ccp     CONSTANT VARCHAR2(5)  := 'XXCCP';                     -- アプリケーション短縮名'XXCCP'
  cv_app_short_name_cok     CONSTANT VARCHAR2(5)  := 'XXCOK';                     -- アプリケーション短縮名'XXCOK'
  -- メッセージ
  cv_no_parameter_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';          -- コンカレント入力パラメータなし
  cv_profile_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';          -- プロファイル値取得エラー
  cv_budget_yser_nodata_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10113';          -- 予算年度情報取得エラー
  cv_budget_yser_many_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10210';          -- 予算年度情報複数件エラー
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00013';          -- 在庫組織ID取得取得エラー
  cv_item_plan_nodata_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10115';          -- 商品計画テーブル情報取得エラー
  cv_item_mst_nodata_msg    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00056';          -- 品目マスタ情報取得エラー
  cv_item_mst_many_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00055';          -- 品目マスタ情報複数件エラー
  cv_cust_mst_nodata_msg    CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10118';          -- 顧客マスタ情報取得エラー
  cv_cust_mst_many_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10119';          -- 顧客マスタ情報複数件エラー
  cv_set_amt_nodata_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10120';          -- 設定単価取得エラー
  cv_set_amt_many_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10121';          -- 設定単価複数件エラー
  cv_case_qty_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10209';          -- ケース入数取得エラーメ
  cv_lock_err_msg           CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10122';          -- 運送費予算ロックエラー
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
  cv_process_date_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';          -- 業務処理日付取得エラー
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
  -- トークン
  cv_profile_token          CONSTANT VARCHAR2(10) := 'PROFILE';                   -- プロファイル名
  cv_budget_year_token      CONSTANT VARCHAR2(20) := 'YOSAN_YEAR';                -- 対象予算年度
  cv_product_class_token    CONSTANT VARCHAR2(20) := 'PRODUCT_CLASS';             -- 商品分類
  cv_location_code_token    CONSTANT VARCHAR2(20) := 'LOCATION_CODE';             -- 拠点コード
  cv_base_major_token       CONSTANT VARCHAR2(20) := 'BASE_MAJOR_DIVISION';       -- 拠点大分類
  cv_item_code_token        CONSTANT VARCHAR2(10) := 'ITEM_CODE';                 -- 品目コード
  cv_org_code_token         CONSTANT VARCHAR2(10) := 'ORG_CODE';                  -- 在庫組織コード
  cv_flex_value_set_token   CONSTANT VARCHAR2(20) := 'FLEX_VALUE_SET';            -- 値セット名
  -- プロファイル名称
  cv_org_code_sales         CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';     -- XXCOK:在庫組織コード_営業組織
  cv_yearplan_calender      CONSTANT VARCHAR2(30) := 'XXCSM1_YEARPLAN_CALENDER';  -- XXCSM:年間販売計画カレンダ
  cv_item_div_h             CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';         -- XXCOS:本社商品区分
  -- 商品区分
  cv_new_item_code          CONSTANT VARCHAR2(1)  := '2';                         -- 新商品
  -- 年間群予算区分
  cv_year_bdgt_kbn          CONSTANT VARCHAR2(1)  := '0';                         -- 各月単位予算
  -- 有効フラグ
  cv_enabled_flag_y         CONSTANT VARCHAR2(1)  := 'Y';                         -- 有効
  -- 配送区分
  cv_dellivary_classe       CONSTANT VARCHAR2(2)  := '41';                        -- 大型車
  -- バラ茶区分
  cn_baracya_type           CONSTANT NUMBER       := 1;                           -- バラ茶
  -- 本社商品区分
  cv_office_item_drink      CONSTANT VARCHAR2(1)  := '2';                         -- ドリンク
  -- ケース入数
  cv_nodata_case_qty        CONSTANT VARCHAR2(1)  := '0';                         -- 未取得
  -- 顧客区分
  cv_customer_class_code    CONSTANT VARCHAR2(1)  := '1';                         -- 拠点
-- == 2010/07/09 V1.7 Added START ===============================================================
  cn_year_5                 CONSTANT NUMBER(1)    := 5;                           --  年度切替月（５月）
-- == 2010/07/09 V1.7 Added END   ===============================================================
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt           NUMBER;                                 -- 対象件数
  gn_normal_cnt           NUMBER;                                 -- 正常件数
  gn_error_cnt            NUMBER;                                 -- エラー件数
  gn_warn_cnt             NUMBER;                                 -- スキップ件数
  gn_data_cnt             NUMBER;                                 -- 商品計画情報取得件数
  gn_organization_id      NUMBER;                                 -- 在庫組織ID
  gv_item_div_h           VARCHAR2(20);                           -- 本社商品区分名
  gt_budget_year          fnd_flex_values.flex_value%TYPE;        -- 対象予算年度
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
  gd_process_date         DATE;                                   -- 業務処理日付
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
  -- ===============================
  -- グローバルRECORD型
  -- ===============================
  -- 運送費予算テーブル
  TYPE g_dlv_cost_budget_rtype IS RECORD(
     budget_year         xxcok_dlv_cost_calc_budget.budget_year%TYPE          -- 予算年度
    ,target_month        xxcok_dlv_cost_calc_budget.target_month%TYPE         -- 月
    ,base_code           xxcok_dlv_cost_calc_budget.base_code%TYPE            -- 拠点コード
    ,item_code           xxcok_dlv_cost_calc_budget.item_code%TYPE            -- 品目コード
    ,bottle_qty          xxcok_dlv_cost_calc_budget.bottle_qty%TYPE           -- 数量（本）
    ,cs_qty              xxcok_dlv_cost_calc_budget.cs_qty%TYPE               -- 数量（CS）
    ,dlv_cost_budget_amt xxcok_dlv_cost_calc_budget.dlv_cost_budget_amt%TYPE  -- 運送費予算金額
  );
  -- ===============================
  -- グローバルTABLE型
  -- ===============================
  -- 運送費予算情報
  TYPE g_dlv_cost_budget_ttype IS TABLE OF g_dlv_cost_budget_rtype
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- グローバルPL/SQL表
  -- ===============================
  -- 運送費予算情報
  g_dlv_cost_budget_tab    g_dlv_cost_budget_ttype;    -- 運送費予算テーブル登録項目PL/SQL表
  -- ===============================
  -- グローバルカーソル
  -- ===============================
  -- 商品計画情報
  CURSOR g_item_plan_cur
  IS
    SELECT xiph.plan_year         AS budget_year    -- 予算年度
          ,xipl.month_no          AS target_month   -- 月
          ,xiph.location_cd       AS base_code      -- 拠点コード
          ,xipl.item_no           AS item_code      -- 商品コード
          ,NVL( xipl.amount, 0 )  AS bottle_qty     -- 数量
    FROM   xxcsm_item_plan_headers xiph
          ,xxcsm_item_plan_lines   xipl
    WHERE xiph.plan_year            =  TO_NUMBER( gt_budget_year )
    AND   xiph.item_plan_header_id  =  xipl.item_plan_header_id
    AND   xipl.item_no              IS NOT NULL
    AND   xipl.item_kbn             <> cv_new_item_code
    AND   xipl.year_bdgt_kbn        =  cv_year_bdgt_kbn
    ORDER BY xipl.month_no    ASC
            ,xiph.location_cd ASC
            ,xipl.item_no     ASC
  ;
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
  global_loop_process_expt    EXCEPTION;      -- メインループ処理中例外
  global_lock_expt            EXCEPTION;      -- ロック処理例外
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,ov_yearplan_calender  OUT VARCHAR2      -- 年間販売計画カレンダの値セット名
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name           CONSTANT VARCHAR2(5) := 'init'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                   VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode                  VARCHAR2(1);       -- リターン・コード
    lv_errmsg                   VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_out_msg                  VARCHAR2(2000);    -- 出力メッセージ
    lb_retcode                  BOOLEAN;           -- メッセージ出力のリターン・コード
    lv_org_code_sales           VARCHAR2(30);      -- 在庫組織コード
    lv_nodata_profile           VARCHAR2(30);      -- 未取得のプロファイル名
    -- *** ローカル例外 ***
    local_nodata_profile_expt   EXCEPTION;         -- プロファイル値取得例外
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
    process_date_expt           EXCEPTION;         -- 業務処理日付取得例外
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 1. メッセージ出力
    -- ===============================
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
    -- ===============================
    -- 2. 在庫組織コード取得
    -- ===============================
    lv_org_code_sales := FND_PROFILE.VALUE( cv_org_code_sales );
    IF( lv_org_code_sales IS NULL ) THEN
      lv_nodata_profile := cv_org_code_sales;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 3. 年間販売計画カレンダの値セット名取得
    -- ===============================
    ov_yearplan_calender := FND_PROFILE.VALUE( cv_yearplan_calender );
    IF( ov_yearplan_calender IS NULL ) THEN
      lv_nodata_profile := cv_yearplan_calender;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 4. 本社商品区分名を取得
    -- ===============================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF( gv_item_div_h IS NULL ) THEN
      lv_nodata_profile := cv_item_div_h;
      RAISE local_nodata_profile_expt;
    END IF;
    -- ===============================
    -- 5. 在庫組織IDの取得
    -- ===============================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_org_code_sales
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE global_no_data_expt;
    END IF;
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
    -- ===============================
    -- 6. 業務処理日付取得
    -- ===============================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      RAISE process_date_expt;
    END IF;
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
--
  EXCEPTION
    --*** プロファイル取得例外ハンドラ ***
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
    --*** 在庫組織ID取得例外ハンドラ ***
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
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
    -- *** 業務処理日付取得例外ハンドラ ***
    WHEN process_date_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_process_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
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
   * Procedure Name   : get_budget_year
   * Description      : 予算年度抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_budget_year(
     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,iv_yearplan_calender  IN  VARCHAR2      -- 年間販売計画カレンダの値セット名
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name     CONSTANT VARCHAR2(20) := 'get_budget_year'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf       VARCHAR2(5000);        -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);           -- リターン・コード
    lv_errmsg       VARCHAR2(5000);        -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000);        -- 出力メッセージ
    lb_retcode      BOOLEAN;               -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 有効な予算年度取得
    -- ===============================
    SELECT ffv.flex_value AS budget_year    -- 対象予算年度
    INTO   gt_budget_year
    FROM   fnd_flex_values     ffv
          ,fnd_flex_value_sets ffvs
    WHERE ffvs.flex_value_set_name  =  iv_yearplan_calender
    AND   ffv.flex_value_set_id     =  ffvs.flex_value_set_id
    AND   ffv.enabled_flag          =  cv_enabled_flag_y
--【2009/03/25 A.Yano Ver.1.4 追加START】------------------------------------------------------
    AND   NVL( ffv.start_date_active, gd_process_date ) <= gd_process_date
    AND   NVL( ffv.end_date_active  , gd_process_date ) >= gd_process_date
--【2009/03/25 A.Yano Ver.1.4 追加END  】------------------------------------------------------
    ;
--
  EXCEPTION
    -- *** 予算年度情報取得例外ハンドラ ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_budget_yser_nodata_msg
                      ,iv_token_name1  => cv_flex_value_set_token
                      ,iv_token_value1 => iv_yearplan_calender
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** 予算年度情報複数件例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_budget_yser_many_msg
                      ,iv_token_name1  => cv_flex_value_set_token
                      ,iv_token_value1 => iv_yearplan_calender
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
  END get_budget_year;
--
  /**********************************************************************************
   * Procedure Name   : get_item_info
   * Description      : 品目マスタ情報抽出処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_item_info(
     ov_errbuf                 OUT VARCHAR2                                -- エラー・メッセージ
    ,ov_retcode                OUT VARCHAR2                                -- リターン・コード
    ,ov_errmsg                 OUT VARCHAR2                                -- ユーザー・エラー・メッセージ
    ,it_item_code              IN  xxcsm_item_plan_lines.item_no%TYPE      -- 商品コード
    ,ot_product_class          OUT xxcmn_item_mst_b.product_class%TYPE     -- 商品分類
    ,ot_godds_classification   OUT ic_item_mst_b.attribute11%TYPE          -- ケース入数
    ,ot_baracha_div            OUT xxcmm_system_items_b.baracha_div%TYPE   -- バラ茶区分
    ,ot_office_item_type       OUT mtl_categories_b.segment1%TYPE          -- 本社商品区分
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name         CONSTANT VARCHAR2(20) := 'get_item_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf           VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);          -- リターン・コード
    lv_errmsg           VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
    lv_out_msg          VARCHAR2(2000);       -- 出力メッセージ
    lb_retcode          BOOLEAN;              -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 品目マスタ情報取得
    -- ===============================
    SELECT ximb.product_class   AS product_class         -- 商品分類
          ,iimb.attribute11     AS godds_classification  -- ケース入数
          ,xsib.baracha_div     AS baracha_div           -- バラ茶区分
          ,mcb.segment1         AS item_div_h            -- 本社商品区分
    INTO   ot_product_class
          ,ot_godds_classification
          ,ot_baracha_div
          ,ot_office_item_type
    FROM   mtl_system_items_b      msib     -- 品目マスタ
          ,ic_item_mst_b           iimb     -- OPM品目マスタ
          ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
          ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
          ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
          ,mtl_item_categories     mic      -- 品目カテゴリ割当
          ,xxcmm_system_items_b    xsib     -- 品目アドオンマスタ
          ,xxcmn_item_mst_b        ximb     -- OPM品目アドオンマスタ
    WHERE  msib.segment1                = iimb.item_no
    AND    iimb.item_id                 = ximb.item_id
    AND    msib.segment1                = xsib.item_code
    AND    msib.inventory_item_id       = mic.inventory_item_id
    AND    msib.organization_id         = mic.organization_id
    AND    mic.category_id              = mcb.category_id
    AND    mcb.structure_id             = mcsb.structure_id
    AND    mic.category_set_id          = mcsb.category_set_id
    AND    mcst.category_set_id         = mcsb.category_set_id
    AND    msib.segment1                = it_item_code
    AND    mcst.language                = USERENV( 'LANG' )
    AND    mcst.category_set_name       = gv_item_div_h
    AND    msib.organization_id         = gn_organization_id
-- 2009/09/03 Ver.1.6 [障害0001257] SCS S.Moriyama ADD START
    AND    gd_process_date BETWEEN ximb.start_date_active
                           AND NVL ( ximb.end_date_active , gd_process_date )
-- 2009/09/03 Ver.1.6 [障害0001257] SCS S.Moriyama ADD END
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** 品目マスタ情報取得例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_mst_nodata_msg
                      ,iv_token_name1  => cv_item_code_token
                      ,iv_token_value1 => it_item_code
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** 品目マスタ情報複数件例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_mst_many_msg
                      ,iv_token_name1  => cv_item_code_token
                      ,iv_token_value1 => it_item_code
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
  END get_item_info;
--
  /**********************************************************************************
   * Procedure Name   : sum_cs_qty
   * Description      : 数量(C/S)算出処理(A-5)
   ***********************************************************************************/
  PROCEDURE sum_cs_qty(
     ov_errbuf                 OUT VARCHAR2                           -- エラー・メッセージ
    ,ov_retcode                OUT VARCHAR2                           -- リターン・コード
    ,ov_errmsg                 OUT VARCHAR2                           -- ユーザー・エラー・メッセージ
    ,it_bottle_qty             IN  xxcsm_item_plan_lines.amount%TYPE  -- 数量
    ,it_godds_classification   IN  ic_item_mst_b.attribute11%TYPE     -- ケース入数
    ,on_cs_qty                 OUT NUMBER                             -- 数量（CS）
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(20) := 'sum_cs_qty'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 数量（CS）算出
    -- ===============================
    on_cs_qty := ROUND( it_bottle_qty / TO_NUMBER( it_godds_classification ) );
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
  END sum_cs_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_mst_info
   * Description      : 顧客マスタ情報抽出処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_mst_info(
     ov_errbuf               OUT VARCHAR2                                  -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                  -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                  -- ユーザー・エラー・メッセージ
    ,it_base_code            IN  xxcsm_item_plan_headers.location_cd%TYPE  -- 拠点コード
    ,ot_base_major_division  OUT xxcmn_parties.base_major_division%TYPE    -- 拠点大分類
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_cust_mst_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf     VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);         -- リターン・コード
    lv_errmsg     VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg    VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode    BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 顧客マスタ情報取得
    -- ===============================
    SELECT xp.base_major_division AS base_major_division   -- 拠点大分類
    INTO   ot_base_major_division
    FROM   hz_parties        hp       -- パーティマスタ
          ,xxcmn_parties     xp       -- パーティアドオンマスタ
          ,hz_cust_accounts  hca      -- 顧客マスタ
    WHERE xp.party_id             = hp.party_id
    AND   hp.party_id             = hca.party_id
    AND   hca.account_number      = it_base_code
    AND   hca.customer_class_code = cv_customer_class_code
    AND   ROWNUM                  = 1
    ;
    -- ===============================
    -- 顧客マスタ情報未取得
    -- ===============================
    IF( ot_base_major_division IS NULL ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** 顧客マスタ情報取得例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_cust_mst_nodata_msg
                      ,iv_token_name1  => cv_location_code_token
                      ,iv_token_value1 => it_base_code
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
  END get_cust_mst_info;
--
  /**********************************************************************************
   * Procedure Name   : get_drink_dlv_cost
   * Description      : ドリンク振替運賃アドオンマスタ情報抽出処理(A-7)
   ***********************************************************************************/
  PROCEDURE get_drink_dlv_cost(
     ov_errbuf               OUT VARCHAR2                                           -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                           -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                           -- ユーザー・エラー・メッセージ
    ,it_budget_year          IN  xxcsm_item_plan_headers.plan_year%TYPE             -- 予算年度
    ,it_target_month         IN  xxcsm_item_plan_lines.month_no%TYPE                -- 月
    ,it_base_code            IN  xxcsm_item_plan_headers.location_cd%TYPE           -- 拠点コード
    ,it_product_class        IN  xxcmn_item_mst_b.product_class%TYPE                -- 商品分類
    ,it_base_major_division  IN  xxcmn_parties.base_major_division%TYPE             -- 拠点大分類
--【2009/05/12 A.Yano Ver.1.5 追加START】------------------------------------------------------
    ,it_item_code            IN  xxcsm_item_plan_lines.item_no%TYPE                 -- 商品コード
--【2009/05/12 A.Yano Ver.1.5 追加END  】------------------------------------------------------
    ,ot_set_unit_price       OUT xxwip_drink_trans_deli_chrgs.setting_amount%TYPE   -- 設定単価
  )
  IS
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name     CONSTANT VARCHAR2(20) := 'get_drink_dlv_cost'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf       VARCHAR2(5000);     --  エラー・メッセージ
    lv_retcode      VARCHAR2(1);        --  リターン・コード
    lv_errmsg       VARCHAR2(5000);     --  ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000);     --  出力メッセージ
    lb_retcode      BOOLEAN;            --  メッセージ出力のリターン・コード
-- == 2010/07/09 V1.7 Added START ===============================================================
    ld_target_date  DATE;               --  マスタ有効チェック用日付
-- == 2010/07/09 V1.7 Added END   ===============================================================
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
-- == 2010/07/09 V1.7 Added START ===============================================================
    IF  (it_target_month <  cn_year_5) THEN
      --  対象月が１月から４月の場合
      ld_target_date  :=  TO_DATE(it_budget_year + 1 || TO_CHAR(it_target_month, 'FM00'), 'YYYYMM');
    ELSE
      --  対象月が上記以外の場合
      ld_target_date  :=  TO_DATE(it_budget_year || TO_CHAR(it_target_month, 'FM00'), 'YYYYMM');
    END IF;
-- == 2010/07/09 V1.7 Added END   ===============================================================
    -- ===============================
    -- ドリンク振替運賃アドオンマスタ情報取得
    -- ===============================
    SELECT xdtd.setting_amount AS setting_amount    -- 設定単価
    INTO   ot_set_unit_price
    FROM   xxwip_drink_trans_deli_chrgs xdtd
    WHERE xdtd.godds_classification   = TO_CHAR( it_product_class )
    AND   xdtd.foothold_macrotaxonomy = it_base_major_division
    AND   xdtd.dellivary_classe       = cv_dellivary_classe
-- == 2010/07/09 V1.7 Modified START ===============================================================
--    AND   TO_DATE( it_budget_year || TO_CHAR( it_target_month, 'FM00' ) , 'YYYYMM' )
    AND   ld_target_date
-- == 2010/07/09 V1.7 Modified END   ===============================================================
          BETWEEN xdtd.start_date_active AND NVL( xdtd.end_date_active, SYSDATE )
    ;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- *** ドリンク振替運賃アドオンマスタ情報取得例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_set_amt_nodata_msg
                      ,iv_token_name1  => cv_product_class_token
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_base_major_token
                      ,iv_token_value2 => it_base_major_division
                      ,iv_token_name3  => cv_location_code_token
                      ,iv_token_value3 => it_base_code
--【2009/05/12 A.Yano Ver.1.5 追加START】------------------------------------------------------
                      ,iv_token_name4  => cv_item_code_token
                      ,iv_token_value4 => it_item_code
--【2009/05/12 A.Yano Ver.1.5 追加END  】------------------------------------------------------
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    WHEN TOO_MANY_ROWS THEN
      -- *** ドリンク振替運賃アドオンマスタ情報複数件例外ハンドラ ****
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_set_amt_many_msg
                      ,iv_token_name1  => cv_product_class_token
                      ,iv_token_value1 => TO_CHAR( it_product_class )
                      ,iv_token_name2  => cv_base_major_token
                      ,iv_token_value2 => it_base_major_division
                      ,iv_token_name3  => cv_location_code_token
                      ,iv_token_value3 => it_base_code
--【2009/05/12 A.Yano Ver.1.5 追加START】------------------------------------------------------
                      ,iv_token_name4  => cv_item_code_token
                      ,iv_token_value4 => it_item_code
--【2009/05/12 A.Yano Ver.1.5 追加END  】------------------------------------------------------
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
  END get_drink_dlv_cost;
--
  /**********************************************************************************
   * Procedure Name   : sum_dlv_cost_budget
   * Description      : 運送費予算金額算出処理(A-8)
   ***********************************************************************************/
  PROCEDURE sum_dlv_cost_budget(
     ov_errbuf               OUT VARCHAR2                                          -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
    ,in_cs_qty               IN  NUMBER                                            -- 数量（CS）
    ,it_set_unit_price       IN  xxwip_drink_trans_deli_chrgs.setting_amount%TYPE  -- 設定単価
    ,on_dlv_cost_budget_amt  OUT NUMBER                                            -- 運送費予算金額
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name     CONSTANT VARCHAR2(30) := 'sum_dlv_cost_budget'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf       VARCHAR2(5000);        -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);           -- リターン・コード
    lv_errmsg       VARCHAR2(5000);        -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000);        -- 出力メッセージ
    lb_retcode      BOOLEAN;               -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 運送費予算金額算出
    -- ===============================
    on_dlv_cost_budget_amt := in_cs_qty * it_set_unit_price;
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
  END sum_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : set_dlv_cost_budget
   * Description      : 運送費予算テーブル登録項目のPL/SQL表格納処理(A-9)
   ***********************************************************************************/
  PROCEDURE set_dlv_cost_budget(
     ov_errbuf               OUT VARCHAR2                 -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2                 -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2                 -- ユーザー・エラー・メッセージ
    ,i_item_plan_rec         IN  g_item_plan_cur%ROWTYPE  -- 商品計画情報
    ,in_cs_qty               IN  NUMBER                   -- 数量（CS）
    ,in_dlv_cost_budget_amt  IN  NUMBER                   -- 運送費予算金額
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'set_dlv_cost_budget'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 運送費予算テーブル登録項目をPL/SQL表へ格納
    -- ===============================
    g_dlv_cost_budget_tab( gn_target_cnt ).budget_year         := TO_CHAR( i_item_plan_rec.budget_year );
    g_dlv_cost_budget_tab( gn_target_cnt ).target_month        := TO_CHAR( i_item_plan_rec.target_month, 'FM00' );
    g_dlv_cost_budget_tab( gn_target_cnt ).base_code           := i_item_plan_rec.base_code;
    g_dlv_cost_budget_tab( gn_target_cnt ).item_code           := i_item_plan_rec.item_code;
    g_dlv_cost_budget_tab( gn_target_cnt ).bottle_qty          := i_item_plan_rec.bottle_qty;
    g_dlv_cost_budget_tab( gn_target_cnt ).cs_qty              := in_cs_qty;
    g_dlv_cost_budget_tab( gn_target_cnt ).dlv_cost_budget_amt := in_dlv_cost_budget_amt;
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
  END set_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : get_item_plan_info
   * Description      : 商品計画テーブル情報抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_item_plan_info(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2      --   リターン・コード
    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name             CONSTANT VARCHAR2(20) := 'get_item_plan_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf               VARCHAR2(5000);                                    -- エラー・メッセージ
    lv_retcode              VARCHAR2(1);                                       -- リターン・コード
    lv_errmsg               VARCHAR2(5000);                                    -- ユーザー・エラー・メッセージ
    lv_out_msg              VARCHAR2(2000);                                    -- 出力メッセージ
    lb_retcode              BOOLEAN;                                           -- メッセージ出力のリターン・コード
    lt_product_class        xxcmn_item_mst_b.product_class%TYPE;               -- 商品分類
    lt_godds_classification ic_item_mst_b.attribute11%TYPE;                    -- ケース入数
    lt_baracha_div          xxcmm_system_items_b.baracha_div%TYPE;             -- バラ茶区分
    lt_office_item_type     mtl_categories_b.segment1%TYPE;                    -- 本社商品区分
    lt_base_code_before     xxcsm_item_plan_headers.location_cd%TYPE;          -- 前回の拠点コード
    lt_base_major_division  xxcmn_parties.base_major_division%TYPE;            -- 拠点大分類
    lt_set_unit_price       xxwip_drink_trans_deli_chrgs.setting_amount%TYPE;  -- 設定単価 NUMBER
    ln_cs_qty               NUMBER;                                            -- 数量（CS）
    ln_dlv_cost_budget_amt  NUMBER;                                            -- 運送費予算金額
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    << item_plan_loop >>
    FOR l_item_plan_rec IN g_item_plan_cur LOOP
      -- 商品計画情報取得件数
      gn_data_cnt := gn_data_cnt + 1;
      -- ================================================
      -- A-4.品目マスタ情報抽出処理
      -- ================================================
      get_item_info(
         ov_errbuf                  =>  lv_errbuf                 -- エラー・メッセージ
        ,ov_retcode                 =>  lv_retcode                -- リターン・コード
        ,ov_errmsg                  =>  lv_errmsg                 -- ユーザー・エラー・メッセージ
        ,it_item_code               =>  l_item_plan_rec.item_code -- 商品コード
        ,ot_product_class           =>  lt_product_class          -- 商品分類
        ,ot_godds_classification    =>  lt_godds_classification   -- ケース入数
        ,ot_baracha_div             =>  lt_baracha_div            -- バラ茶区分
        ,ot_office_item_type        =>  lt_office_item_type       -- 本社商品区分
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- バラ茶区分1:バラ茶または、
      -- 本社商品区分'2'ドリンク以外の場合
      -- ===============================
      IF(  ( lt_baracha_div      =  cn_baracya_type      )
        OR( lt_office_item_type <> cv_office_item_drink ) )
      THEN
        -- スキップ件数
        gn_warn_cnt   := gn_warn_cnt + 1;
      ELSE
        -- ===============================
        -- ケース入数未取得
        -- ===============================
        IF( ( lt_godds_classification IS NULL              )
          OR( lt_godds_classification = cv_nodata_case_qty ) )
        THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_short_name_cok
                          ,iv_name         => cv_case_qty_err_msg
                          ,iv_token_name1  => cv_item_code_token
                          ,iv_token_value1 => l_item_plan_rec.item_code
                        );
          RAISE global_no_data_expt;
        END IF;
        -- 処理続行
        -- ================================================
        -- A-5.数量(C/S)算出処理
        -- ================================================
        sum_cs_qty(
           ov_errbuf                    =>  lv_errbuf                   -- エラー・メッセージ
          ,ov_retcode                   =>  lv_retcode                  -- リターン・コード
          ,ov_errmsg                    =>  lv_errmsg                   -- ユーザー・エラー・メッセージ
          ,it_bottle_qty                =>  l_item_plan_rec.bottle_qty  -- 数量
          ,it_godds_classification      =>  lt_godds_classification     -- ケース入数
          ,on_cs_qty                    =>  ln_cs_qty                   -- 数量（CS）
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-6.顧客マスタ情報抽出処理
        -- ================================================
        -- 初回取得時または、拠点が変わった場合
        IF( ( lt_base_major_division IS NULL                      )
          OR( lt_base_code_before    <> l_item_plan_rec.base_code ) )
        THEN
          lt_base_code_before := l_item_plan_rec.base_code;
          get_cust_mst_info(
             ov_errbuf                 =>   lv_errbuf                 -- エラー・メッセージ
            ,ov_retcode                =>   lv_retcode                -- リターン・コード
            ,ov_errmsg                 =>   lv_errmsg                 -- ユーザー・エラー・メッセージ
            ,it_base_code              =>   l_item_plan_rec.base_code -- 拠点コード
            ,ot_base_major_division    =>   lt_base_major_division    -- 拠点大分類
          );
          IF( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
        -- ================================================
        -- A-7.ドリンク振替運賃アドオンマスタ情報抽出処理
        -- ================================================
        get_drink_dlv_cost(
           ov_errbuf                    =>   lv_errbuf                     -- エラー・メッセージ
          ,ov_retcode                   =>   lv_retcode                    -- リターン・コード
          ,ov_errmsg                    =>   lv_errmsg                     -- ユーザー・エラー・メッセージ
          ,it_budget_year               =>   l_item_plan_rec.budget_year   -- 予算年度
          ,it_target_month              =>   l_item_plan_rec.target_month  -- 月
          ,it_base_code                 =>   l_item_plan_rec.base_code     -- 拠点コード
          ,it_product_class             =>   lt_product_class              -- 商品分類
          ,it_base_major_division       =>   lt_base_major_division        -- 拠点大分類
--【2009/05/12 A.Yano Ver.1.5 追加START】------------------------------------------------------
          ,it_item_code                 =>   l_item_plan_rec.item_code     -- 商品コード
--【2009/05/12 A.Yano Ver.1.5 追加END  】------------------------------------------------------
          ,ot_set_unit_price            =>   lt_set_unit_price             -- 設定単価
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-8.運送費予算金額算出処理
        -- ================================================
        sum_dlv_cost_budget(
           ov_errbuf                    =>   lv_errbuf                -- エラー・メッセージ
          ,ov_retcode                   =>   lv_retcode               -- リターン・コード
          ,ov_errmsg                    =>   lv_errmsg                -- ユーザー・エラー・メッセージ
          ,in_cs_qty                    =>   ln_cs_qty                -- 数量（CS）
          ,it_set_unit_price            =>   lt_set_unit_price        -- 設定単価
          ,on_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- 運送費予算金額
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ================================================
        -- A-9.運送費予算テーブル登録項目のPL/SQL表格納処理
        -- ================================================
        set_dlv_cost_budget(
           ov_errbuf                    =>   lv_errbuf                -- エラー・メッセージ
          ,ov_retcode                   =>   lv_retcode               -- リターン・コード
          ,ov_errmsg                    =>   lv_errmsg                -- ユーザー・エラー・メッセージ
          ,i_item_plan_rec              =>   l_item_plan_rec          -- 商品計画情報
          ,in_cs_qty                    =>   ln_cs_qty                -- 数量（CS）
          ,in_dlv_cost_budget_amt       =>   ln_dlv_cost_budget_amt   -- 運送費予算金額
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 対象件数
        gn_target_cnt := gn_target_cnt + 1;
      END IF;
    END LOOP item_plan_loop;
    -- ===============================
    -- 抽出データ0件の場合
    -- ===============================
    IF( gn_data_cnt = 0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_item_plan_nodata_msg
                      ,iv_token_name1  => cv_budget_year_token
                      ,iv_token_value1 => gt_budget_year
                    );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** データ取得例外ハンドラ ****
    WHEN global_no_data_expt THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
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
  END get_item_plan_info;
--
  /**********************************************************************************
   * Procedure Name   : delete_dlv_cost_budget
   * Description      : 運送費予算テーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE delete_dlv_cost_budget(
     ov_errbuf       OUT VARCHAR2                                  --   エラー・メッセージ
    ,ov_retcode      OUT VARCHAR2                                  --   リターン・コード
    ,ov_errmsg       OUT VARCHAR2                                  --   ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'delete_dlv_cost_budget'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
    -- *** ローカルカーソル ***
    CURSOR l_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_dlv_cost_calc_budget xdcc
      WHERE  xdcc.budget_year = TO_CHAR( gt_budget_year )
      FOR UPDATE OF xdcc.budget_id NOWAIT
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 運送費予算テーブルロック取得
    -- ===============================
    OPEN  l_lock_cur;
    CLOSE l_lock_cur;
    -- ===============================
    -- 運送費予算テーブル削除
    -- ===============================
    DELETE FROM xxcok_dlv_cost_calc_budget xdcc
    WHERE xdcc.budget_year = TO_CHAR( gt_budget_year )
    ;
--
  EXCEPTION
    -- *** 運送費予算ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_lock_err_msg
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
  END delete_dlv_cost_budget;
--
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_budget
   * Description      : 運送費予算テーブル登録処理(A-11)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_budget(
     ov_errbuf     OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_budget'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- ===============================
    -- 運送費予算テーブル登録
    -- ===============================
    << insert_loop >>
    FOR cnt IN g_dlv_cost_budget_tab.FIRST..g_dlv_cost_budget_tab.LAST LOOP
      INSERT INTO xxcok_dlv_cost_calc_budget(
         budget_id                -- 運送費予算ID
        ,budget_year              -- 予算年度
        ,target_month             -- 月
        ,base_code                -- 拠点コード
        ,item_code                -- 品目コード
        ,bottle_qty               -- 数量（本）
        ,cs_qty                   -- 数量（CS）
        ,dlv_cost_budget_amt      -- 運送費予算金額
        --WHOカラム
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      ) VALUES (
         xxcok_dlv_cost_calc_budget_s01.nextval            -- 運送費予算ID
        ,g_dlv_cost_budget_tab( cnt ).budget_year          -- 予算年度
        ,g_dlv_cost_budget_tab( cnt ).target_month         -- 月
        ,g_dlv_cost_budget_tab( cnt ).base_code            -- 拠点コード
        ,g_dlv_cost_budget_tab( cnt ).item_code            -- 品目コード
        ,g_dlv_cost_budget_tab( cnt ).bottle_qty           -- 数量（本）
        ,g_dlv_cost_budget_tab( cnt ).cs_qty               -- 数量（CS）
        ,g_dlv_cost_budget_tab( cnt ).dlv_cost_budget_amt  -- 運送費予算金額
        --WHOカラム
        ,cn_created_by
        ,SYSDATE
        ,cn_last_updated_by
        ,SYSDATE
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,SYSDATE
      );
      -- 正常件数
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP insert_loop;
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
  END insert_dlv_cost_budget;
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
    lv_errbuf              VARCHAR2(5000);                          -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);                             -- リターン・コード
    lv_errmsg              VARCHAR2(5000);                          -- ユーザー・エラー・メッセージ
    lv_out_msg             VARCHAR2(2000);                          -- 出力メッセージ
    lb_retcode             BOOLEAN;                                 -- メッセージ出力のリターン・コード
    lv_yearplan_calender   VARCHAR2(30);                            -- 年間販売計画カレンダの値セット名
    lt_budget_year         xxcsm_item_plan_headers.plan_year%TYPE;  -- 商品計画情報
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_data_cnt   := 0;
    -- ====================================
    -- A-1.初期処理
    -- ====================================
    init(
       ov_errbuf              =>   lv_errbuf               -- エラー・メッセージ
      ,ov_retcode             =>   lv_retcode              -- リターン・コード
      ,ov_errmsg              =>   lv_errmsg               -- ユーザー・エラー・メッセージ
      ,ov_yearplan_calender   =>   lv_yearplan_calender    -- 年間販売計画カレンダの値セット名
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-2.予算年度抽出処理
    -- ====================================
    get_budget_year(
       ov_errbuf              =>   lv_errbuf               -- エラー・メッセージ
      ,ov_retcode             =>   lv_retcode              -- リターン・コード
      ,ov_errmsg              =>   lv_errmsg               -- ユーザー・エラー・メッセージ
      ,iv_yearplan_calender   =>   lv_yearplan_calender    -- 年間販売計画カレンダの値セット名
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-3.商品計画テーブル情報抽出処理
    -- ====================================
    get_item_plan_info(
       ov_errbuf       =>    lv_errbuf              -- エラー・メッセージ
      ,ov_retcode      =>    lv_retcode             -- リターン・コード
      ,ov_errmsg       =>    lv_errmsg              -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ====================================
    -- A-10.運送費予算テーブル削除処理
    -- ====================================
    -- 登録データがあり且つ、エラーがない場合
    IF( g_dlv_cost_budget_tab.COUNT > 0 ) THEN
      delete_dlv_cost_budget(
         ov_errbuf       =>    lv_errbuf          -- エラー・メッセージ
        ,ov_retcode      =>    lv_retcode         -- リターン・コード
        ,ov_errmsg       =>    lv_errmsg          -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ====================================
      -- A-11.運送費予算テーブル登録処理
      -- ====================================
      insert_dlv_cost_budget(
         ov_errbuf     =>    lv_errbuf              -- エラー・メッセージ
        ,ov_retcode    =>    lv_retcode             -- リターン・コード
        ,ov_errmsg     =>    lv_errmsg              -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
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
    lv_errbuf         VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);          -- リターン・コード
    lv_errmsg         VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
    lv_out_msg        VARCHAR2(2000);       -- 出力メッセージ
    lv_message_code   VARCHAR2(100);        -- 終了メッセージ
    lb_retcode        BOOLEAN;              -- メッセージ出力のリターン・コード
--
  BEGIN
--
    -- コンカレントヘッダメッセージ出力関数の呼び出し
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
    --エラー出力
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
    -- 異常終了の場合の件数セット
    IF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --対象件数出力
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
--
    --成功件数出力
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
--
    --エラー件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   1
                  );
--
    --終了メッセージ
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
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
END XXCOK023A01C;
/
