CREATE OR REPLACE PACKAGE BODY XXCOK023A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A04C(body)
 * Description      : 運送費実績情報と運送費予算情報を集計し、運送費管理表(速報)をCSV形式で作成します。
 * MD.050           : 運送費管理表出力 MD050_COK_023_A04
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                  初期処理(A-1)
 *  put_file_date         運送費管理表の要求出力処理(A-6)
 *  get_budget_data       運送費予算情報取得処理(A-5)
 *  get_result_info_data  運送費実績情報取得処理(A-3)
 *  get_base_data         拠点抽出処理(A-2)
 *  get_put_file_data     要求出力対象データの取得・出力処理(A-2 ～ A-6)
 *  submain               メイン処理プロシージャ
 *  main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.0   SCS T.Taniguchi  新規作成
 *  2009/02/06    1.1   SCS T.Taniguchi  [障害COK_018] クイックコードビューの有効日・無効日の判定追加
 *  2009/03/02    1.2   SCS T.Taniguchi  [障害COK_070] 入力パラメータ「職責タイプ」により、拠点の取得範囲を制御
 *  2009/10/02    1.3   SCS S.Moriyama   [障害E_T3_00630] VDBM残高一覧表が出力されない（同類不具合調査）
 *
 *****************************************************************************************/
--
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1) := '.';
  cn_number_0               CONSTANT NUMBER        := 0;
  cn_number_1               CONSTANT NUMBER        := 1;
  cn_month_5                CONSTANT NUMBER        := 5; -- 5月
-- グローバル変数
  gv_out_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_sep_msg                VARCHAR2(2000) DEFAULT NULL;
  gv_exec_user              VARCHAR2(100)  DEFAULT NULL;
  gv_conc_name              VARCHAR2(30)   DEFAULT NULL;
  gv_conc_status            VARCHAR2(30)   DEFAULT NULL;
  gn_target_cnt             NUMBER DEFAULT 0;       -- 対象件数
  gn_normal_cnt             NUMBER DEFAULT 0;       -- 正常件数
  gn_error_cnt              NUMBER DEFAULT 0;       -- エラー件数
  gn_warn_cnt               NUMBER DEFAULT 0;       -- スキップ件数
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
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(12) := 'XXCOK023A04C'; -- パッケージ名
  -- メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
  cv_warn_msg               CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006'; -- エラー終了メッセージ
  cv_msg_xxccp1_90000       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000'; -- 対象件数出力
  cv_msg_xxccp1_90001       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001'; -- 成功件数出力
  cv_msg_xxccp1_90002       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002'; -- エラー件数出力
  cv_msg_xxccp1_90003       CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003'; -- スキップ件数出力
  cv_msg_xxcok1_10186       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10186'; -- 対象データ無し
  cv_msg_xxcok1_00052       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00052'; -- 職責ID取得エラー
  cv_msg_xxcok1_10182       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10182'; -- 拠点取得エラー
  cv_msg_xxcok1_00018       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00018'; -- コンカレント入力パラメータ(拠点コード)
  cv_msg_xxcok1_00020       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00020'; -- コンカレント入力パラメータ2(年度)
  cv_msg_xxcok1_00021       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00021'; -- コンカレント入力パラメータ3(月)
  cv_msg_xxcok1_00012       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00012'; -- 所属拠点エラー
  cv_msg_xxcok1_10367       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10367'; -- 要求出力エラー
  cv_msg_xxcok1_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015'; -- クイックコード取得エラー
  cv_msg_xxcok1_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028'; -- 業務処理日付取得エラー
  -- トークン
  cv_year                   CONSTANT VARCHAR2(4)  := 'YEAR';             -- 年度
  cv_month                  CONSTANT VARCHAR2(5)  := 'MONTH';            -- 月
  cv_resp_name              CONSTANT VARCHAR2(9)  := 'RESP_NAME';        -- 職責名
  cv_location_code          CONSTANT VARCHAR2(13) := 'LOCATION_CODE';    -- 拠点コード
  cv_count                  CONSTANT VARCHAR2(5)  := 'COUNT';            -- 処理件数
  cv_token_lookup_value_set CONSTANT VARCHAR2(16) := 'LOOKUP_VALUE_SET'; -- 参照タイプ
  cv_user_id                CONSTANT VARCHAR2(7)  := 'USER_ID';          -- ユーザーID
  -- application_short_name
  cv_appl_name_xxcok        CONSTANT VARCHAR2(5)  := 'XXCOK'; -- アプリケーションショートネーム(XXCOK)
  cv_appl_name_xxccp        CONSTANT VARCHAR2(5)  := 'XXCCP'; -- アプリケーションショートネーム(XXCCP)
  -- 値セット名
  cv_flex_st_name_department  CONSTANT VARCHAR2(15) := 'XX03_DEPARTMENT'; -- 部門
  -- 参照タイプ
  cv_lookup_type_put_val      CONSTANT VARCHAR2(30)  := 'XXCOK1_COST_MANAGEMENT_PUT_VAL';
  -- その他
  cv_yyyymmdd               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD'; -- 日付フォーマット
  cv_yyyymm                 CONSTANT VARCHAR2(6)   := 'YYYYMM';     -- 日付フォーマット
  cv_dd                     CONSTANT VARCHAR2(2)   := 'DD';         -- 日付フォーマット
  cv_dy                     CONSTANT VARCHAR2(2)   := 'DY';         -- 日付フォーマット
  cv_cust_cd_base           CONSTANT VARCHAR2(1)   := '1';          -- 顧客区分('1':拠点)
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';          -- カンマ
  cv_kbn_koguchi            CONSTANT VARCHAR2(1)   := '1';          -- 小口区分('1':小口)
  cv_kbn_syatate            CONSTANT VARCHAR2(1)   := '0';          -- 小口区分('0':車立)
  cv_resp_name_val          CONSTANT VARCHAR2(100) := fnd_global.resp_name; -- 職責名
  cv_resp_type_1            CONSTANT VARCHAR2(1)   := '1';          -- 本部部門担当者職責
  cv_resp_type_2            CONSTANT VARCHAR2(1)   := '2';          -- 拠点部門_担当者職責
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_base_code            VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの拠点コード
  gv_budget_year          VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの予算年度
  gv_result_year          VARCHAR2(4)  DEFAULT NULL; -- 入力パラメータの年度
  gv_budget_month         VARCHAR2(2)  DEFAULT NULL; -- 入力パラメータの月
  gn_resp_id              NUMBER       DEFAULT NULL; -- ログイン職責ID
  gn_user_id              NUMBER       DEFAULT NULL; -- ログインユーザーID
  gn_last_day             NUMBER       DEFAULT NULL; -- 月末日
  gd_process_date         DATE         DEFAULT NULL; -- 業務処理日付
  gv_resp_type            VARCHAR2(1)  DEFAULT NULL; -- 職責タイプ
--
  -- ===============================
  -- レコードタイプの宣言部
  -- ===============================
--
  -- 拠点情報のレコードタイプ
  TYPE base_rec IS RECORD(
    base_code        VARCHAR2(4), -- 拠点コード
    base_name        VARCHAR2(50) -- 拠点名
  );
--
  -- ===============================
  -- テーブルタイプの宣言部
  -- ===============================
  -- 拠点情報のテーブルタイプ
  TYPE base_tbl IS TABLE OF base_rec INDEX BY BINARY_INTEGER;
  -- 金額・数量データ格納
  TYPE number_tbl IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  -- 編集データ格納
  TYPE varchar2_tbl IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
--
  /**********************************************************************************
   * Procedure Name   : put_file_date
   * Description      : 運送費管理表の要求出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE put_file_date(
    ov_errbuf                  OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code               IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_base_name               IN  VARCHAR2 DEFAULT NULL, -- 拠点名
    i_result_syatate_amt_ttype IN  number_tbl,            -- 実績(車立)_金額
    i_result_koguchi_amt_ttype IN  number_tbl,            -- 実績(小口)_金額
    i_sum_amt_ttype            IN  number_tbl,            -- 合計
    i_total_amt_ttype          IN  number_tbl,            -- 累計
    in_sum_syatate_amt         IN  NUMBER DEFAULT 0,      -- 拠点計_車立金額
    in_sum_koguchi_amt         IN  NUMBER DEFAULT 0,      -- 拠点計_小口金額
    in_sum_budget_amt          IN  NUMBER DEFAULT 0,      -- 拠点計_予算金額
    in_sum_result_amt          IN  NUMBER DEFAULT 0,      -- 拠点計_実績金額
    in_sum_diff_amt            IN  NUMBER DEFAULT 0)      -- 拠点計_差額金額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'put_file_date'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    -- *** ローカル・カーソル ***
    -- 見出し取得カーソル
    CURSOR put_value_cur
    IS
      SELECT attribute1 AS put_val
      FROM   xxcok_lookups_v
      WHERE  lookup_type = cv_lookup_type_put_val
      AND    NVL( start_date_active,gd_process_date ) <= gd_process_date  -- 適用開始日
      AND    NVL( end_date_active,gd_process_date )   >= gd_process_date  -- 適用終了日
      ORDER BY TO_NUMBER(lookup_code)
    ;
    TYPE put_value_ttype IS TABLE OF put_value_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    put_value_tab put_value_ttype;
    -- *** ローカル変数 ***
    lv_day        VARCHAR2(2)    DEFAULT NULL; -- 曜日
    lv_manth_day  VARCHAR2(12)   DEFAULT NULL; -- 入庫年月日
    lb_retcode    BOOLEAN;
    ln_target_cnt NUMBER         DEFAULT 0;    -- クイックコードデータ取得件数
    -- *** 例外 ***
    no_data_expt             EXCEPTION;      -- データ取得エラー
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    OPEN  put_value_cur;
    FETCH put_value_cur BULK COLLECT INTO put_value_tab;
    CLOSE put_value_cur;
    -- ===============================================
    -- 対象件数取得
    -- ===============================================
    ln_target_cnt := put_value_tab.COUNT;
    IF ( ln_target_cnt = 0 ) THEN
      RAISE no_data_expt;
    END IF;
    -- ===============================
    -- 拠点行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(1).put_val || iv_base_code || cv_comma || iv_base_name, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- ===============================
    -- 項目名行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(2).put_val,    --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- 日別データ行出力(1日～月末)
    <<day_loop>>
    FOR i IN 1..gn_last_day LOOP
      -- 曜日の取得
      lv_day := TO_CHAR( TO_DATE( gv_result_year || TO_CHAR( gv_budget_month,'FM00' )
                || TO_CHAR( i,'FM00' ),cv_yyyymmdd ),cv_dy );
      -- 入庫年月日の編集
      lv_manth_day := gv_budget_month || put_value_tab(8).put_val || i
                      || put_value_tab(9).put_val || put_value_tab(10).put_val || lv_day || put_value_tab(11).put_val;
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT, --OUTPUT
                      iv_message  => lv_manth_day || cv_comma || i_result_syatate_amt_ttype(i)
                                     || cv_comma || i_result_koguchi_amt_ttype(i)
                                     || cv_comma || i_sum_amt_ttype(i)
                                     || cv_comma || i_total_amt_ttype(i),--出力データ
                      in_new_line => cn_number_0      -- 改行数
                    );
    END LOOP day_loop;
    -- ===============================
    -- 拠点計_車立金額行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(3).put_val || in_sum_syatate_amt, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- ===============================
    -- 拠点計_小口金額行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(4).put_val || in_sum_koguchi_amt, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- ===============================
    -- 拠点計_予算金額行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(5).put_val || in_sum_budget_amt, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- ===============================
    -- 拠点計_実績金額行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(6).put_val || in_sum_result_amt, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
    -- ===============================
    -- 拠点計_差額金額行出力
    -- ===============================
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT, --OUTPUT
                    iv_message  => put_value_tab(7).put_val || in_sum_diff_amt, --出力データ
                    in_new_line => cn_number_0      -- 改行数
                  );
--
  EXCEPTION
    -- *** データ取得例外 ***
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00015
                    , iv_token_name1  => cv_token_lookup_value_set
                    , iv_token_value1 => cv_lookup_type_put_val
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
--
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END put_file_date;
--
  /**********************************************************************************
   * Procedure Name   : get_budget_data
   * Description      : 運送費予算情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_budget_data(
    ov_errbuf                   OUT   VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT   VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT   VARCHAR2, -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code                IN    xxcok_dlv_cost_result_info.base_code%TYPE  DEFAULT NULL, -- 拠点コード
    ot_budget_amt               OUT   NUMBER)   -- 予算_金額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_budget_data'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    BEGIN
      -- ===============================
      -- 運送費予算情報取得
      -- ===============================
      -- 運送費予算テーブルより「年度」、「月」、「拠点コード」を条件に、運送費予算金額を集計する
      SELECT NVL( SUM( dlv_cost_budget_amt ),0 )
      INTO   ot_budget_amt
      FROM   xxcok_dlv_cost_calc_budget
      WHERE  budget_year  = gv_budget_year
      AND    target_month = TO_CHAR( gv_budget_month,'FM00' )
      AND    base_code    = iv_base_code
      ;
    EXCEPTION
      -- *** NO_DATA_FOUND ***
      WHEN NO_DATA_FOUND THEN
        ot_budget_amt := 0;
    END;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_budget_data;
--
  /**********************************************************************************
   * Procedure Name   : get_result_info_data
   * Description      : 運送費実績情報取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_result_info_data(
    ov_errbuf                   OUT   VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT   VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT   VARCHAR2, -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code                IN    xxcok_dlv_cost_result_info.base_code%TYPE DEFAULT NULL,     -- 拠点コード
    id_arrival_date             IN    xxcok_dlv_cost_result_info.arrival_date%TYPE DEFAULT NULL,  -- 着荷日
    ot_result_syatate_amt       OUT   xxcok_dlv_cost_result_info.dlv_cost_result_amt%TYPE, -- 実績(車立)_金額
    ot_result_koguchi_amt       OUT   xxcok_dlv_cost_result_info.dlv_cost_result_amt%TYPE, -- 実績(小口)_金額
    on_sum_amt                  OUT   NUMBER)                                              -- 合計_金額
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(20) := 'get_result_info_data'; -- プログラム名
--
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    -- *** ローカル・カーソル ***
    -- 運送費実績カーソル
    CURSOR result_info_cur(
      i_base_code    IN xxcok_dlv_cost_result_info.base_code%TYPE,      -- 拠点コード
      i_arrival_date IN xxcok_dlv_cost_result_info.arrival_date%TYPE)   -- 着荷日
    IS
      SELECT small_amt_type                      AS small_amt_type, -- 小口区分
             NVL( SUM( dlv_cost_result_amt ),0 ) AS result_sum_amt  -- 実績集計金額
      FROM   xxcok_dlv_cost_result_info
      WHERE  target_year           = gv_result_year
      AND    target_month          = TO_CHAR( gv_budget_month,'FM00' )
      AND    base_code             = i_base_code
      AND    TRUNC( arrival_date ) = i_arrival_date
      GROUP BY small_amt_type
      ORDER BY small_amt_type
    ;
    -- 運送費実績カーソルレコード型
    result_info_rec result_info_cur%ROWTYPE;
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- 実績数量・金額デフォルト設定
    ot_result_syatate_amt := 0; -- 実績(車立)_金額
    ot_result_koguchi_amt := 0; -- 実績(小口)_金額
    on_sum_amt            := 0; -- 合計_金額
    -- ===============================
    -- 運送費実績情報取得処理
    -- ===============================
    <<result_info_loop>>
    FOR result_info_rec IN result_info_cur(
      iv_base_code,     -- 拠点コード
      id_arrival_date   -- 着荷日
      ) LOOP
      -- ===============================
      -- 実績金額格納処理
      -- ===============================
      -- 小口区分別に金額を設定
      -- 車立の場合
      IF ( result_info_rec.small_amt_type = cv_kbn_syatate ) THEN
        ot_result_syatate_amt := result_info_rec.result_sum_amt; -- 実績(車立)_金額
        -- 合計金額集計
        on_sum_amt := on_sum_amt + result_info_rec.result_sum_amt;
      -- 小口の場合
      ELSIF ( result_info_rec.small_amt_type = cv_kbn_koguchi ) THEN
        ot_result_koguchi_amt := result_info_rec.result_sum_amt; -- 実績(小口)_金額
        -- 合計金額集計
        on_sum_amt := on_sum_amt + result_info_rec.result_sum_amt;
      ELSE
        -- 合計金額集計
        on_sum_amt := on_sum_amt + 0;
      END IF;
    END LOOP result_info_loop;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_result_info_data;
--
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 拠点抽出処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf           OUT    VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT    VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg           OUT    VARCHAR2, -- ユーザー・エラー・メッセージ --# 固定 #
    o_budget_ttype      OUT    base_tbl) -- 拠点情報
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(13) := 'get_base_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    -- *** ローカル変数 ***
    ln_base_index     NUMBER       DEFAULT 1;    -- 拠点情報用インデックス
    lv_resp_nm        VARCHAR2(40) DEFAULT NULL; -- 職責名
    ln_main_resp_id   NUMBER       DEFAULT NULL; -- 本部部門担当者
    ln_sales_resp_id  NUMBER       DEFAULT NULL; -- 拠点部門担当者
    lv_belong_base_cd VARCHAR2(4)  DEFAULT NULL; -- 所属拠点
    lb_retcode        BOOLEAN;
    -- *** ローカル・カーソル ***
    -- 職責IDカーソル
    CURSOR resp_id_cur(
      iv_resp_name IN VARCHAR2) -- 職責名
    IS
      SELECT responsibility_id AS responsibility_id
      FROM   fnd_responsibility_vl
      WHERE  responsibility_name = iv_resp_name
    ;
    -- 職責IDカーソルレコード型
    resp_id_rec resp_id_cur%ROWTYPE;
    -- 拠点名カーソル
    CURSOR base_name_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT account_name AS base_name
      FROM   hz_cust_accounts
      WHERE  account_number      = iv_base_code
      AND    customer_class_code = cv_cust_cd_base -- 拠点
    ;
    -- 拠点名カーソルレコード型
    base_name_rec base_name_cur%ROWTYPE;
    -- 配下拠点カーソル
    CURSOR child_base_cur(
      iv_base_code IN VARCHAR2) -- 拠点コード
    IS
      SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
              hca.account_name            AS base_name  -- 拠点名
      FROM    fnd_flex_value_norm_hierarchy ffvnh,
              fnd_flex_values_vl ffvv,
              hz_cust_accounts hca
      WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                         FROM   fnd_flex_value_sets ffvs,
                                                fnd_flex_value_norm_hierarchy ffvnh
                                         WHERE  ffvs.flex_value_set_name    = cv_flex_st_name_department
                                         AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                         AND    ffvnh.child_flex_value_high = iv_base_code -- 所属拠点コード
                                        )
      AND     ffvv.value_category         = cv_flex_st_name_department
      AND     ffvnh.child_flex_value_high = ffvv.flex_value
      AND     hca.account_number          = ffvv.flex_value
      AND     hca.customer_class_code     = cv_cust_cd_base -- 拠点
      ORDER BY ffvnh.child_flex_value_high
    ;
    -- 配下拠点カーソルレコード型
    child_base_rec child_base_cur%ROWTYPE;
    -- *** ローカル・例外 ***
    no_resp_id_expt EXCEPTION;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 拠点情報の取得
    -- ===============================
    -- 入力パラメータの拠点情報を取得
    IF ( gv_base_code IS NOT NULL ) THEN
      <<base_name_loop>>
      FOR base_name_rec IN base_name_cur( gv_base_code ) LOOP
        o_budget_ttype(ln_base_index).base_code := gv_base_code;            -- 拠点コード
        o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name; -- 拠点名
      END LOOP base_name_loop;
      -- 拠点情報が取得できなかった場合
      IF ( o_budget_ttype(1).base_name IS NULL ) THEN
        -- エラー処理
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_10182,
                       iv_token_name1  => cv_resp_name,
                       iv_token_value1 => cv_resp_name_val,
                       iv_token_name2  => cv_location_code,
                       iv_token_value2 => gv_base_code
                     );
        lv_errbuf := lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE global_process_expt;
      END IF;
    -- 職責別に拠点を取得
    ELSE
      -- 共通関数より自拠点コードを取得する
-- 2009/10/02 Ver.1.3 [障害E_T3_00630] SCS S.Moriyama UPD START
--      lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( SYSDATE,gn_user_id );
      lv_belong_base_cd := xxcok_common_pkg.get_base_code_f( gd_process_date, gn_user_id );
-- 2009/10/02 Ver.1.3 [障害E_T3_00630] SCS S.Moriyama UPD END
      -- 自拠点コードが取得できなかった場合
      IF lv_belong_base_cd IS NULL THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcok,
                       iv_name         => cv_msg_xxcok1_00012,
                       iv_token_name1  => cv_user_id,
                       iv_token_value1 => gn_user_id
                     );
        lv_errbuf := lv_errmsg;
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG
                      , iv_message  => lv_errmsg
                      , in_new_line => cn_number_0
                      );
        RAISE global_process_expt;
      END IF;
      -- ===============================
      -- 職責別の拠点取得処理
      -- ===============================
      -- 本部部門担当者職責の場合
      IF ( gv_resp_type = cv_resp_type_1 ) THEN
        -- ログインユーザーの自拠点より配下の拠点を取得
        <<child_base_loop>>
        FOR child_base_rec IN child_base_cur( lv_belong_base_cd ) LOOP
          o_budget_ttype(ln_base_index).base_code := child_base_rec.base_code; -- 拠点コード
          o_budget_ttype(ln_base_index).base_name := child_base_rec.base_name; -- 拠点名
          ln_base_index := ln_base_index + 1;
        END LOOP child_base_loop;
      -- 拠点部門_担当者職責の場合
      ELSE
        -- 自拠点を取得
        o_budget_ttype(ln_base_index).base_code   := lv_belong_base_cd;        -- 拠点コード
        <<resp_loop>>
        FOR base_name_rec IN base_name_cur( lv_belong_base_cd ) LOOP
          o_budget_ttype(ln_base_index).base_name := base_name_rec.base_name;  -- 拠点名
        END LOOP resp_loop;
      END IF;
    END IF;
--
  EXCEPTION
    --*** 職責ID取得エラー ***
    WHEN no_resp_id_expt THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_00052,
                      iv_token_name1  => cv_resp_name,
                      iv_token_value1 => lv_resp_nm
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : get_put_file_data
   * Description      : 要求出力対象データの取得・出力処理(A-2 ～ A-6)
   ***********************************************************************************/
  PROCEDURE get_put_file_data(
    ov_errbuf     OUT VARCHAR2, -- エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2, -- リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2) -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(17) := 'get_put_file_data'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    l_base_ttype                base_tbl;
    l_base_loop_index           NUMBER DEFAULT NULL;
    ld_target_date              DATE;
    -- 集計用変数
    ln_result_syatate_amt       NUMBER DEFAULT 0; -- 実績(車立)_金額
    ln_result_koguchi_amt       NUMBER DEFAULT 0; -- 実績(小口)_金額
    ln_sum_syatate_amt          NUMBER DEFAULT 0; -- 拠点計_車立金額
    ln_sum_koguchi_amt          NUMBER DEFAULT 0; -- 拠点計_小口金額
    ln_sum_budget_amt           NUMBER DEFAULT 0; -- 拠点計_予算金額
    ln_sum_result_amt           NUMBER DEFAULT 0; -- 拠点計_実績金額
    ln_sum_diff_amt             NUMBER DEFAULT 0; -- 拠点計_差額金額
    ln_sum_amt                  NUMBER DEFAULT 0; -- 合計_金額
    ln_total_amt                NUMBER DEFAULT 0; -- 累計_金額
    -- 出力編集後格納変数
    l_result_syatate_amt_ttype  number_tbl; -- 実績(車立)_金額
    l_result_koguchi_amt_ttype  number_tbl; -- 実績(小口)_金額
    l_sum_amt_ttype             number_tbl; -- 合計
    l_total_amt_ttype           number_tbl; -- 累計
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 拠点データの取得(A-2.)
    -- ===============================
    get_base_data(
      ov_errbuf      => lv_errbuf,    -- エラー・メッセージ
      ov_retcode     => lv_retcode,   -- リターン・コード
      ov_errmsg      => lv_errmsg,    -- ユーザー・エラー・メッセージ
      o_budget_ttype => l_base_ttype  -- 拠点情報
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    l_base_loop_index := l_base_ttype.FIRST;
    -- 取得した拠点の数分ループします
    <<base_loop>>
    WHILE ( l_base_loop_index IS NOT NULL ) LOOP
      -- 初期化
      ln_result_syatate_amt   := 0;      -- 実績(車立)_金額
      ln_result_koguchi_amt   := 0;      -- 実績(小口)_金額
      ln_sum_amt              := 0;      -- 合計
      ln_total_amt            := 0;      -- 累計
      ln_sum_syatate_amt      := 0;      -- 拠点計_車立金額
      ln_sum_koguchi_amt      := 0;      -- 拠点計_小口金額
      ln_sum_budget_amt       := 0;      -- 拠点計_予算金額
      ln_sum_result_amt       := 0;      -- 拠点計_実績金額
      ln_sum_diff_amt         := 0;      -- 拠点計_差額金額
      l_result_syatate_amt_ttype.DELETE; -- 実績(車立)_金額
      l_result_koguchi_amt_ttype.DELETE; -- 実績(小口)_金額
      l_sum_amt_ttype.DELETE;            -- 合計
      l_total_amt_ttype.DELETE;          -- 累計
      -- ===============================
      -- 日別ループ
      -- ===============================
      <<day_loop>>
      FOR i IN 1..gn_last_day LOOP
        -- 処理対象日
        ld_target_date := TO_DATE( gv_result_year || TO_CHAR( gv_budget_month, 'FM00' )
                          || TO_CHAR( i, 'FM00' ),cv_yyyymmdd );
        -- ===============================
        -- 運送費実績情報取得処理(A-3)
        -- ===============================
        get_result_info_data(
          ov_errbuf             => lv_errbuf,    -- エラー・メッセージ
          ov_retcode            => lv_retcode,   -- リターン・コード
          ov_errmsg             => lv_errmsg,    -- ユーザー・エラー・メッセージ
          iv_base_code          => l_base_ttype(l_base_loop_index).base_code, -- 拠点コード
          id_arrival_date       => ld_target_date,                            -- 着荷日
          ot_result_syatate_amt => ln_result_syatate_amt,                     -- 実績(車立)_金額
          ot_result_koguchi_amt => ln_result_koguchi_amt,                     -- 実績(小口)_金額
          on_sum_amt            => ln_sum_amt                                 -- 合計_金額
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- 実績データPL/SQL表格納処理(A-4.)
        -- ===============================
        -- 日別の金額をPL/SQL表に格納する
        l_result_syatate_amt_ttype(i) := ln_result_syatate_amt;     -- 実績(車立)_金額
        l_result_koguchi_amt_ttype(i) := ln_result_koguchi_amt;     -- 実績(小口)_金額
        l_sum_amt_ttype(i)            := ln_sum_amt;                -- 合計_金額
        ln_total_amt                  := ln_total_amt + ln_sum_amt; -- 累計金額の集計
        l_total_amt_ttype(i)          := ln_total_amt;              -- 累計金額
        -- 金額を集計
        ln_sum_syatate_amt   := ln_sum_syatate_amt + ln_result_syatate_amt; -- 拠点計_車立金額
        ln_sum_koguchi_amt   := ln_sum_koguchi_amt + ln_result_koguchi_amt; -- 拠点計_小口金額
        ln_sum_result_amt    := ln_sum_result_amt + ln_sum_amt;             -- 拠点計_実績金額
      END LOOP day_loop;
      -- ===============================
      -- 運送費予算情報取得処理(A-5)
      -- ===============================
      get_budget_data(
        ov_errbuf     => lv_errbuf,                                 -- エラー・メッセージ           --# 固定 #
        ov_retcode    => lv_retcode,                                -- リターン・コード             --# 固定 #
        ov_errmsg     => lv_errmsg,                                 -- ユーザー・エラー・メッセージ --# 固定 #
        iv_base_code  => l_base_ttype(l_base_loop_index).base_code, -- 拠点コード
        ot_budget_amt => ln_sum_budget_amt                          -- 予算_金額
      );
      -- 実績金額と予算金額が取得できた場合(予算・実績ともに金額が0の場合、要求出力しない)
      IF ( ln_sum_budget_amt > 0 ) OR ( ln_total_amt > 0 ) THEN
        -- 差額計算
        ln_sum_diff_amt := ln_sum_budget_amt - ln_total_amt;
        -- 対象件数カウント
        gn_target_cnt := gn_target_cnt + 1;
        -- ===============================
        -- 運送費管理表の要求出力処理(A-6)
        -- ===============================
        put_file_date(
          ov_errbuf                  => lv_errbuf,    -- エラー・メッセージ
          ov_retcode                 => lv_retcode,   -- リターン・コード
          ov_errmsg                  => lv_errmsg,    -- ユーザー・エラー・メッセージ
          iv_base_code               => l_base_ttype(l_base_loop_index).base_code, -- 拠点コード
          iv_base_name               => l_base_ttype(l_base_loop_index).base_name, -- 拠点名
          i_result_syatate_amt_ttype => l_result_syatate_amt_ttype,                -- 実績(車立)_金額
          i_result_koguchi_amt_ttype => l_result_koguchi_amt_ttype,                -- 実績(小口)_金額
          i_sum_amt_ttype            => l_sum_amt_ttype,                           -- 合計
          i_total_amt_ttype          => l_total_amt_ttype,                         -- 累計
          in_sum_syatate_amt         => ln_sum_syatate_amt,                        -- 拠点計_車立金額
          in_sum_koguchi_amt         => ln_sum_koguchi_amt,                        -- 拠点計_小口金額
          in_sum_budget_amt          => ln_sum_budget_amt,                         -- 拠点計_予算金額
          in_sum_result_amt          => ln_sum_result_amt,                         -- 拠点計_実績金額
          in_sum_diff_amt            => ln_sum_diff_amt                            -- 拠点計_差額金額
        );
        -- エラー判定
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
      -- 次のインデックスを番号を取得
      l_base_loop_index := l_base_ttype.NEXT(l_base_loop_index);
    END LOOP base_loop;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_put_file_data;
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 年度
    iv_budget_month IN  VARCHAR2 DEFAULT NULL, -- 月
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(4) := 'init'; -- プログラム名
--
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    -- *** ローカル変数 ***
    lv_profile_nm   VARCHAR2(30) DEFAULT NULL; -- プロファイル名称の格納用
    lb_retcode      BOOLEAN;
    -- *** ローカル・例外 ***
    no_profile_expt EXCEPTION; -- プロファイル値取得エラー
    no_process_date EXCEPTION; -- 業務日付取得エラー
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- ===============================
    -- 入力パラメータの退避
    -- ===============================
    gv_base_code    := iv_base_code;    -- 拠点コード
    gv_budget_year  := iv_budget_year;  -- 年度
    gv_resp_type    := iv_resp_type;    -- 職責タイプ
    -- 1～4月は年度の翌年とし、5～12月は年度とする
    IF ( TO_NUMBER( iv_budget_month ) < cn_month_5 ) THEN
      gv_result_year  := TO_NUMBER( iv_budget_year ) + 1;  -- 年度
    ELSE
      gv_result_year  := TO_NUMBER( iv_budget_year );      -- 年度
    END IF;
    gv_budget_month := iv_budget_month; -- 月
    -- ===============================
    -- 入力パラメータの出力
    -- ===============================
    -- コンカレント入力パラメータメッセージ出力(1:拠点コード)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00018,
                    iv_token_name1  => cv_location_code,
                    iv_token_value1 => gv_base_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_0   -- 改行数
                  );
    -- コンカレント入力パラメータメッセージ出力(2:年度)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00020,
                    iv_token_name1  => cv_year,
                    iv_token_value1 => gv_budget_year
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_0   -- 改行数
                  );
    -- コンカレント入力パラメータメッセージ出力(3:月)
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcok,
                    iv_name         => cv_msg_xxcok1_00021,
                    iv_token_name1  => cv_month,
                    iv_token_value1 => gv_budget_month
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_1   -- 改行数
                  );
    -- ===============================
    -- 月末日の取得
    -- ===============================
    -- 入力パラメータの年度と月より月末日を取得する
    gn_last_day := TO_NUMBER( TO_CHAR( LAST_DAY( TO_DATE( gv_result_year
                   || TO_CHAR( gv_budget_month,'FM00' ),cv_yyyymm ) ),cv_dd ) );
    -- ===============================
    -- ログイン時の情報取得
    -- ===============================
    gn_resp_id := fnd_global.resp_id; -- 職責ID
    gn_user_id := fnd_global.user_id; -- ユーザーID
    -- =============================================
    -- 業務処理日付取得
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG
                    , iv_message  => lv_errmsg
                    , in_new_line => cn_number_0
                    );
      RAISE no_process_date;
    END IF;
--
  EXCEPTION
    --*** 業務日付取得取得エラー ***
    WHEN no_process_date THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( gv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf       OUT VARCHAR2,              -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,              -- リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2,              -- ユーザー・エラー・メッセージ --# 固定 #
    iv_base_code    IN  VARCHAR2 DEFAULT NULL, -- 拠点コード
    iv_budget_year  IN  VARCHAR2 DEFAULT NULL, -- 年度
    iv_budget_month IN  VARCHAR2 DEFAULT NULL, -- 月
    iv_resp_type    IN  VARCHAR2 DEFAULT NULL  -- 職責タイプ
    )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(7) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;     -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      ov_errbuf       => lv_errbuf,       -- エラー・メッセージ
      ov_retcode      => lv_retcode,      -- リターン・コード
      ov_errmsg       => lv_errmsg,       -- ユーザー・エラー・メッセージ
      iv_base_code    => iv_base_code,    -- 拠点コード
      iv_budget_year  => iv_budget_year,  -- 年度
      iv_budget_month => iv_budget_month, -- 月
      iv_resp_type    => iv_resp_type     -- 職責タイプ
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================
    -- 要求出力対象データ取得処理(A2～A6)
    -- ===============================
    get_put_file_data(
      lv_errbuf,  -- エラー・メッセージ           --# 固定 #
      lv_retcode, -- リターン・コード             --# 固定 #
      lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2, -- エラー・メッセージ --# 固定 #
    retcode         OUT VARCHAR2, -- リターン・コード   --# 固定 #
    iv_base_code    IN  VARCHAR2, -- 1.拠点コード
    iv_budget_year  IN  VARCHAR2, -- 2.年度
    iv_budget_month IN  VARCHAR2, -- 3.月
    iv_resp_type    IN  VARCHAR2  -- 4.職責タイプ
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(4)  := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT NULL; -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(16)   DEFAULT NULL; -- メッセージコード
    lb_retcode      BOOLEAN;
--
  BEGIN
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
      iv_which   => 'LOG',--cn_fut_kbn_log, -- ログ出力
      ov_retcode => lv_retcode,
      ov_errbuf  => lv_errbuf,
      ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- submainの呼び出し
    -- ===============================
    submain(
      ov_errbuf        => lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      ov_retcode       => lv_retcode,     -- リターン・コード             --# 固定 #
      ov_errmsg        => lv_errmsg,      -- ユーザー・エラー・メッセージ --# 固定 #
      iv_base_code    => iv_base_code,    -- 拠点コード
      iv_budget_year  => iv_budget_year,  -- 年度
      iv_budget_month => iv_budget_month, -- 月
      iv_resp_type    => iv_resp_type     -- 職責タイプ
    );
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG, -- LOG
                      iv_message  => lv_errbuf ,   -- メッセージ
                      in_new_line => cn_number_1   -- 改行数
                    );
      -- 対象件数・成功件数・エラー件数の設定
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    -- 出力件数が0件の場合
    IF (gn_normal_cnt = 0) AND ( lv_retcode = cv_status_normal )THEN
      -- 対象データ無しのメッセージ出力
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok,
                      iv_name         => cv_msg_xxcok1_10186,
                      iv_token_name1  => cv_year,
                      iv_token_value1 => gv_budget_year,
                      iv_token_name2  => cv_month,
                      iv_token_value2 => gv_budget_month
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.LOG, -- LOG
                     iv_message  => gv_out_msg,   -- メッセージ
                     in_new_line => cn_number_1   -- 改行数
                    );
    END IF;
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90000,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_0   -- 改行数
                  );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90001,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_0   -- 改行数
                  );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => cv_msg_xxccp1_90002,
                    iv_token_name1  => cv_count,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_1   -- 改行数
                  );
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxccp,
                    iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG, -- LOG
                    iv_message  => gv_out_msg,   -- メッセージ
                    in_new_line => cn_number_0   -- 改行数
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK023A04C;
/
