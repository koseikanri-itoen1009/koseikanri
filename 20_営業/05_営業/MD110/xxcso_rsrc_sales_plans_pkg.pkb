CREATE OR REPLACE PACKAGE BODY APPS.xxcso_rsrc_sales_plans_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rsrc_sales_plans_pkg(BODY)
 * Description      : 訪問売上計画共通関数(営業・営業領域）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  --------------------------- ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------------- ---- ----- --------------------------------------------------
 *  init_transaction             P    -     売上計画トランザクション初期化
 *  init_transaction_bulk        P    -     売上計画(複数顧客)トランザクション初期化
 *  process_lock                 P    -     トランザクションロック
 *  get_rsrc_monthly_plan        F    -     営業員計画情報 月間売上計画取得
 *  get_acct_monthly_plan_sum    F    -     営業員計画情報 設定済売上計画の取得
 *  get_rsrc_acct_differ         F    -     営業員計画情報 差額取得
 *  get_acct_daily_plan_sum      F    -     顧客別売上計画（月別）設定済日別計画取得
 *  get_rsrc_acct_daily_differ   F    -     顧客別売上計画（月別）差額取得
 *  update_rsrc_acct_monthly     P    -     顧客別売上計画（月別）の登録更新
 *  update_rsrc_acct_daily       P    -     顧客別売上計画（日別）の登録更新
 *  delete_rsrc_acct_daily       P    -     顧客別売上計画（日別）の削除
 *  get_party_id                 F    -     パーティIDの取得
 *  distrbt_upd_rsrc_acct_daily  P    -     顧客別売上計画日別按分処理＆更新登録処理
 *  delete_rsrc_acct_daily       P    -     顧客別売上計画（日別）の削除
 *  update_rsrc_acct_daily2      P    -     顧客別売上計画（日別）の登録更新２
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Boku           新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_rsrc_sales_plans_pkg';   -- パッケージ名
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  nowait_except       EXCEPTION;
  PRAGMA EXCEPTION_INIT(nowait_except, -54);
--
  /**********************************************************************************
   * Function Name    : init_transaction
   * Description      : 売上計画トランザクション初期化
   ***********************************************************************************/
  -- 売上計画トランザクション初期化
  PROCEDURE init_transaction(
    iv_base_code             IN  VARCHAR2
   ,iv_account_number        IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'init_transaction';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_count                     NUMBER;
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    SELECT  COUNT('x')
    INTO    ln_count
    FROM    xxcso_tmp_sales_plan;
--
    IF ( ln_count <> 0 ) THEN
--
      UPDATE   xxcso_tmp_sales_plan
      SET      base_code         = iv_base_code
              ,account_number    = iv_account_number
              ,year_month        = iv_year_month
              ,created_by        = fnd_global.user_id
              ,creation_date     = SYSDATE
              ,last_updated_by   = fnd_global.user_id
              ,last_update_date  = SYSDATE
              ,last_update_login = fnd_global.login_id
      ;
--
    ELSE
--
      INSERT INTO xxcso_tmp_sales_plan(
                    base_code
                   ,account_number
                   ,year_month
                   ,created_by
                   ,creation_date
                   ,last_updated_by
                   ,last_update_date
                   ,last_update_login
                 )
          VALUES (
                    iv_base_code
                   ,iv_account_number
                   ,iv_year_month
                   ,fnd_global.user_id
                   ,SYSDATE
                   ,fnd_global.user_id
                   ,SYSDATE
                   ,fnd_global.login_id
                 )
      ;
--
    END IF;
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END init_transaction;
--
  /**********************************************************************************
   * Function Name    : init_transaction_bulk
   * Description      : 売上計画(複数顧客)トランザクション初期化
   ***********************************************************************************/
  -- 売上計画(複数顧客)トランザクション初期化
  PROCEDURE init_transaction_bulk(
    iv_base_code             IN  VARCHAR2
   ,iv_employee_number       IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'init_transaction_bulk';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_count                     NUMBER;
    ld_year_month                DATE;

  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    SELECT  COUNT('x')
    INTO    ln_count
    FROM    xxcso_tmp_sales_plan;
--
    IF ( ln_count <> 0 ) THEN
--
      DELETE   xxcso_tmp_sales_plan;
--
    END IF;
--
    ld_year_month := TO_DATE(iv_year_month, 'YYYYMM');
--
--  営業員担当顧客VIEWより、従業員番号に紐付く顧客コードを取得し、
--  ワークテーブルへレコード追加する。
    INSERT INTO
      xxcso_tmp_sales_plan(
        base_code
       ,account_number
       ,year_month
       ,employee_number
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_update_date
       ,last_update_login
      )
      SELECT iv_base_code
            ,xrcv.account_number
            ,iv_year_month
            ,xrcv.employee_number
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.user_id
            ,SYSDATE
            ,fnd_global.login_id
        FROM xxcso_resource_custs_v xrcv
       WHERE xrcv.employee_number  = iv_employee_number
         AND TRUNC(
               xrcv.start_date_active
              ,'MM') <= ld_year_month
         AND TRUNC(
               NVL(xrcv.end_date_active
                  ,ld_year_month
               )
              ,'MM') >= ld_year_month
    ;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END init_transaction_bulk;
--
   /**********************************************************************************
   * Function Name    : process_lock
   * Description      : トランザクションロック処理
   ***********************************************************************************/
  PROCEDURE process_lock(
    in_trgt_account_sales_plan_id  IN  NUMBER
   ,id_trgt_last_update_date       IN  DATE
   ,in_next_account_sales_plan_id  IN  NUMBER
   ,id_next_last_update_date       IN  DATE
   ,ov_errbuf                      OUT NOCOPY VARCHAR2
   ,ov_retcode                     OUT NOCOPY VARCHAR2
   ,ov_errmsg                      OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_lock';
    -- ===============================
    -- ローカル変数
    -- ===============================
    ld_trgt_last_update_date     DATE;
    ld_next_last_update_date     DATE;
    lb_exception_flag            BOOLEAN;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_exception_flag := FALSE;
--
    BEGIN
--
      -- 当月
      IF ( in_trgt_account_sales_plan_id IS NOT NULL ) THEN
	      SELECT  xasp.last_update_date
	        INTO  ld_trgt_last_update_date
	        FROM  xxcso_account_sales_plans  xasp
	       WHERE  xasp.account_sales_plan_id = in_trgt_account_sales_plan_id
	         FOR UPDATE NOWAIT
	      ;
	  END IF;
--
      -- 翌月
      IF ( in_next_account_sales_plan_id IS NOT NULL ) THEN
	      SELECT  xasp.last_update_date
	        INTO  ld_next_last_update_date
	        FROM  xxcso_account_sales_plans  xasp
	       WHERE  xasp.account_sales_plan_id = in_next_account_sales_plan_id
	         FOR UPDATE NOWAIT
	      ;
	  END IF;
--
    EXCEPTION
      -- *** NO_DATA_FOUNDハンドラ ***
      WHEN NO_DATA_FOUND THEN
        RETURN;
--
      WHEN nowait_except THEN
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00002';
        lb_exception_flag := TRUE;
        RETURN;
--
    END;
--
    IF ( lb_exception_flag = FALSE ) THEN
--
      -- 当月
      if ( in_trgt_account_sales_plan_id IS NOT NULL AND
           id_trgt_last_update_date <> ld_trgt_last_update_date ) THEN
--
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00003';
--
      END IF;
--
      -- 翌月
      if ( in_next_account_sales_plan_id IS NOT NULL AND
           id_next_last_update_date <> ld_next_last_update_date ) THEN
--
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00003';
--
      END IF;
--
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END process_lock;
--
  /**********************************************************************************
   * Function Name    : get_rsrc_monthly_plan
   * Description      : 営業員計画情報 月間売上計画取得
   *                    営業員別月別計画テーブルの売上計画開示区分により
   *                    目標売上（営業員計：計）または、基本売上（営業員計：計）を取得
   ***********************************************************************************/
  FUNCTION get_rsrc_monthly_plan(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_monthly_plan';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_plan_amt                  NUMBER;
--
  BEGIN
--
    SELECT
            (CASE
               WHEN ( xdmp.sales_plan_rel_div = '1' ) THEN  -- 目標売上計画
                 xspmp.tgt_sales_prsn_total_amt             -- 目標売上（営業員計：計）
               ELSE                                         -- 基本売上計画
                 xspmp.bsc_sls_prsn_total_amt               -- 基本売上（営業員計：計）
             END
            ) AS plan_amt
      INTO  ln_plan_amt
      FROM  xxcso_sls_prsn_mnthly_plns xspmp,      -- 営業員別月別計画テーブル
            xxcso_dept_monthly_plans xdmp          -- 拠点別月別計画テーブル
     WHERE  xspmp.base_code       = iv_base_code
       AND  xspmp.year_month      = iv_year_month
       AND  xspmp.employee_number = iv_employee_number
       AND  xdmp.base_code        = xspmp.base_code
       AND  xdmp.year_month       = xspmp.year_month
       AND  ROWNUM                = 1;
--
    RETURN TO_CHAR(ln_plan_amt, 'FM9G999G999G990');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_rsrc_monthly_plan;
--
--
--
/**********************************************************************************
 * Function Name    : get_acct_monthly_plan_sum
 * Description      : 営業員計画情報 設定済売上計画の取得
 *                    （営業員の）顧客別売上計画テーブルの月別売上計画を集計
 ***********************************************************************************/
  FUNCTION get_acct_monthly_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_acct_monthly_plan_sum';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_plan_amt                  NUMBER;
    ld_plan_date                 DATE;
--
  BEGIN
--
    ld_plan_date := TO_DATE(iv_year_month, 'YYYYMM');
--
    SELECT  SUM(xasp.sales_plan_month_amt)
      INTO  ln_plan_amt
      FROM  xxcso_account_sales_plans xasp,
            xxcso_resource_custs_v xrcv
     WHERE  xasp.base_code                             = iv_base_code
       AND  xasp.account_number                        = xrcv.account_number
       AND  xasp.year_month                            = iv_year_month
       AND  xasp.month_date_div                        = '1'  -- 月別計画
       AND  xrcv.employee_number                       = iv_employee_number
       AND  TRUNC(xrcv.start_date_active, 'DD')       <= ld_plan_date
       AND  NVL(xrcv.end_date_active, ld_plan_date)   >= ld_plan_date;
--
    RETURN TO_CHAR(ln_plan_amt, 'FM999G999G990');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_acct_monthly_plan_sum;
--
  /**********************************************************************************
   * Function Name    : get_rsrc_acct_differ
   * Description      : 営業員計画情報 差額取得
   *                    月間売上計画－設定済売上計画
   ***********************************************************************************/
  FUNCTION get_rsrc_monthly_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_monthly_differ';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_plan_month                NUMBER;
    ln_plan_daily_sum            NUMBER;
  BEGIN
    -- 月間売上計画を取得
    ln_plan_month := 
      TO_NUMBER(
        get_rsrc_monthly_plan(
          iv_base_code, iv_employee_number, iv_year_month), 'FM999G999G990');
--
    -- 設定済売上計画を取得
    ln_plan_daily_sum := 
      TO_NUMBER(
        get_acct_monthly_plan_sum(
          iv_base_code, iv_employee_number, iv_year_month), 'FM999G999G990');
--
    -- 月間売上計画＞０（≠NULL）の場合、差額を計算する。
    -- 設定済売上計画＝NULLの場合、０として計算する。
    IF ( NVL(ln_plan_month, 0) > 0 ) THEN
      RETURN TO_CHAR(ln_plan_month - NVL(ln_plan_daily_sum, 0), 'FM999G999G990');
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_rsrc_monthly_differ;
--
--
--
  /**********************************************************************************
   * Function Name    : get_acct_daily_plan_sum
   * Description      : 顧客別売上計画（月別）設定済日別計画取得
   *                    顧客別売上計画テーブルの日別売上計画を集計
   ***********************************************************************************/
  FUNCTION get_acct_daily_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_acct_daily_plan_sum';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_plan_amt                  NUMBER;
--
  BEGIN
--
    SELECT  SUM(xasp.sales_plan_day_amt)
      INTO  ln_plan_amt
      FROM  xxcso_account_sales_plans xasp
     WHERE  xasp.base_code       = iv_base_code
       AND  xasp.account_number  = iv_account_number
       AND  xasp.year_month      = iv_year_month
       AND  xasp.month_date_div  = '2';  -- 日別計画
--
    RETURN TO_CHAR(ln_plan_amt, 'FM999G999G990');
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_acct_daily_plan_sum;
--
--
--
  /**********************************************************************************
   * Function Name    : get_rsrc_acct_daily_differ
   * Description      : 顧客別売上計画（月別）差額取得
   *                    差額＝月間売上計画－設定済日別計画
   ***********************************************************************************/
  FUNCTION get_rsrc_acct_daily_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_acct_daily_differ';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_plan_month                NUMBER;
    ln_plan_daily_sum            NUMBER;
--
  BEGIN
--
    -- 顧客別売上計画テーブルの月間売上計画を取得
    BEGIN
      SELECT  xasp.sales_plan_month_amt
        INTO  ln_plan_month
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.year_month     = iv_year_month
         AND  xasp.month_date_div = '1'  -- 月別計画
         AND  ROWNUM              = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_plan_month := 0;
    END;
--
    -- 設定済日別計画を取得
    ln_plan_daily_sum := 
      TO_NUMBER(
        get_acct_daily_plan_sum(
          iv_base_code, iv_account_number, iv_year_month), 'FM999G999G990');
--
    -- 月間売上計画＞０（≠NULL）の場合、差額を計算する。
    -- 設定済日別計画＝NULLの場合、０として計算する。
    IF ( NVL(ln_plan_month, 0) > 0 ) THEN
      RETURN TO_CHAR(ln_plan_month - NVL(ln_plan_daily_sum, 0), 'FM999G999G990');
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_rsrc_acct_daily_differ;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_monthly
   * Description      : 顧客別売上計画（月別）の登録更新
   *                    訪問・売上計画画面／売上計画(複数顧客)
   ***********************************************************************************/
  PROCEDURE update_rsrc_acct_monthly(
    in_account_sales_plan_id    IN  NUMBER
   ,iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
   ,iv_sales_plan_month_amt     IN  VARCHAR2
   ,iv_distribute_flg           IN  VARCHAR2
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_monthly';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sales_plan_month_amt      NUMBER;
    lv_period_year               VARCHAR2(4);
    ln_pary_id                   NUMBER;
    ln_cnt                       NUMBER  := 0;
    lv_update_func_div           VARCHAR2(1) := '3';     -- 訪問・売上計画画面
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER型に変換
    ln_sales_plan_month_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_month_amt, ',', '')
         );
--
    -- 顧客別売上計画テーブルの月間売上計画の存在チェック
    IF ( in_account_sales_plan_id IS NOT NULL ) THEN
      SELECT  COUNT(xasp.account_sales_plan_id)
        INTO  ln_cnt
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
    END IF;
--
    -- 更新機能区分
    IF ( NVL(iv_distribute_flg, '0') = '1'  ) THEN
      lv_update_func_div := '4';  -- 売上計画(複数顧客)
    END IF;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- 顧客別売上計画テーブルの月間売上計画を更新
      UPDATE  xxcso_account_sales_plans xasp
         SET  xasp.sales_plan_month_amt = ln_sales_plan_month_amt
             ,update_func_div           = lv_update_func_div
             ,xasp.last_updated_by      = fnd_global.user_id
             ,xasp.last_update_date     = SYSDATE
             ,xasp.last_update_login    = fnd_global.login_id
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
--
    ELSE
--
      -- 会計年度取得
      SELECT  TO_CHAR(glp.period_year)
        INTO  lv_period_year
        FROM  gl_sets_of_books  glb  -- 会計帳簿マスタ
             ,gl_periods        glp  -- 会計カレンダテーブル
       WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
         AND  glp.period_set_name              = glb.period_set_name
         AND  TO_CHAR(glp.start_date,'YYYYMM') = iv_year_month
         AND  glp.adjustment_period_flag       = 'N';
--
      -- パーティID取得
      ln_pary_id := get_party_id(iv_account_number);
--
      -- 顧客別売上計画テーブルの月間売上計画を登録
      INSERT  INTO xxcso_account_sales_plans xasp
              (xasp.account_sales_plan_id
              ,xasp.base_code
              ,xasp.account_number
              ,xasp.year_month
              ,xasp.plan_day
              ,xasp.fiscal_year
              ,xasp.month_date_div
              ,xasp.sales_plan_month_amt
              ,xasp.plan_date
              ,xasp.party_id
              ,xasp.update_func_div
              ,xasp.created_by
              ,xasp.creation_date
              ,xasp.last_updated_by
              ,xasp.last_update_date
              ,xasp.last_update_login)
       VALUES (
               xxcso_account_sales_plans_s01.NEXTVAL
              ,iv_base_code
              ,iv_account_number
              ,iv_year_month
              ,'99'
              ,lv_period_year
              ,'1'                          -- 月別
              ,ln_sales_plan_month_amt
              ,iv_year_month || '99'
              ,ln_pary_id
              ,lv_update_func_div           -- 更新機能区分
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.login_id);
--
    END IF;
--
      RETURN;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END update_rsrc_acct_monthly;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_daily
   * Description      : 顧客別売上計画（日別）の登録更新／訪問・売上計画画面
   ***********************************************************************************/
  PROCEDURE update_rsrc_acct_daily(
    in_account_sales_plan_id    IN  NUMBER
   ,iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
   ,iv_sales_plan_day_amt       IN  VARCHAR2
   ,in_party_id                 IN  NUMBER
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_daily';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sales_plan_day_amt        NUMBER;
    lv_period_year               VARCHAR2(4);
    ln_cnt                       NUMBER;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER型に変換
    ln_sales_plan_day_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_day_amt, ',', '')
         );
--
    -- 顧客別売上計画テーブルの日別売上計画の存在チェック
    IF ( in_account_sales_plan_id IS NOT NULL ) THEN
      SELECT  COUNT(xasp.account_sales_plan_id)
        INTO  ln_cnt
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
    END IF;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- 顧客別売上計画テーブルの月間売上計画を更新
      UPDATE  xxcso_account_sales_plans xasp
         SET  xasp.sales_plan_day_amt   = ln_sales_plan_day_amt
             ,xasp.update_func_div      = '3'
             ,xasp.last_updated_by      = fnd_global.user_id
             ,xasp.last_update_date     = SYSDATE
             ,xasp.last_update_login    = fnd_global.login_id
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
--
    ELSE
--
      -- 会計年度取得
      SELECT  TO_CHAR(glp.period_year)
        INTO  lv_period_year
        FROM  gl_sets_of_books  glb  -- 会計帳簿マスタ
             ,gl_periods        glp  -- 会計カレンダテーブル
       WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
         AND  glp.period_set_name              = glb.period_set_name
         AND  TO_CHAR(glp.start_date,'YYYYMM') = SUBSTR(iv_plan_date, 1, 6)
         AND  glp.adjustment_period_flag       = 'N';
--
      -- 顧客別売上計画テーブルの月間売上計画を登録
      INSERT  INTO xxcso_account_sales_plans xasp
              (xasp.account_sales_plan_id
              ,xasp.base_code
              ,xasp.account_number
              ,xasp.year_month
              ,xasp.plan_day
              ,xasp.fiscal_year
              ,xasp.month_date_div
              ,xasp.sales_plan_day_amt
              ,xasp.plan_date
              ,xasp.party_id
              ,xasp.update_func_div
              ,xasp.created_by
              ,xasp.creation_date
              ,xasp.last_updated_by
              ,xasp.last_update_date
              ,xasp.last_update_login)
       VALUES (
               xxcso_account_sales_plans_s01.NEXTVAL
              ,iv_base_code
              ,iv_account_number
              ,SUBSTR(iv_plan_date, 1, 6)
              ,SUBSTR(iv_plan_date, 7, 2)
              ,lv_period_year
              ,'2'                          -- 日別
              ,ln_sales_plan_day_amt
              ,iv_plan_date
              ,in_party_id
              ,'3'                          -- 訪問売上計画
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.login_id);
--
    END IF;
--
    RETURN;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END update_rsrc_acct_daily;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_daily2
   * Description      : 顧客別売上計画（日別）の登録更新／売上計画(複数顧客)
   ***********************************************************************************/
  PROCEDURE update_rsrc_acct_daily2(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
   ,it_sales_plan_day_amt       IN  xxcso_account_sales_plans.sales_plan_day_amt%TYPE
   ,in_party_id                 IN  NUMBER
   ,iv_period_year              IN  VARCHAR2
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_daily2';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_cnt                       NUMBER;
    lt_sales_plan_amt_edit       xxcso_account_sales_plans.sales_plan_day_amt%TYPE := NULL;
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- 日別売上計画＝0の場合、NULLクリア
    IF ( it_sales_plan_day_amt > 0 ) THEN
      lt_sales_plan_amt_edit := it_sales_plan_day_amt;
    END IF;
--
    -- 顧客別売上計画テーブルの日別売上計画の存在チェック
    SELECT  COUNT(xasp.account_sales_plan_id)
      INTO  ln_cnt
      FROM  xxcso_account_sales_plans xasp
     WHERE  xasp.base_code      = iv_base_code
       AND  xasp.account_number = iv_account_number
       AND  xasp.plan_date      = iv_plan_date
       AND  xasp.month_date_div = '2'   -- 日別
    ;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- 顧客別売上計画テーブルの日別売上計画を更新
      UPDATE  xxcso_account_sales_plans xasp
         SET  xasp.sales_plan_day_amt   = lt_sales_plan_amt_edit
             ,xasp.update_func_div      = '4'
             ,xasp.last_updated_by      = fnd_global.user_id
             ,xasp.last_update_date     = SYSDATE
             ,xasp.last_update_login    = fnd_global.login_id
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.plan_date      = iv_plan_date
         AND  xasp.month_date_div = '2'   -- 日別
      ;
--
    ELSE
--
      -- 顧客別売上計画テーブルの月間売上計画を登録
      INSERT  INTO xxcso_account_sales_plans xasp
              (xasp.account_sales_plan_id
              ,xasp.base_code
              ,xasp.account_number
              ,xasp.year_month
              ,xasp.plan_day
              ,xasp.fiscal_year
              ,xasp.month_date_div
              ,xasp.sales_plan_day_amt
              ,xasp.plan_date
              ,xasp.party_id
              ,xasp.update_func_div
              ,xasp.created_by
              ,xasp.creation_date
              ,xasp.last_updated_by
              ,xasp.last_update_date
              ,xasp.last_update_login)
       VALUES (
               xxcso_account_sales_plans_s01.NEXTVAL
              ,iv_base_code
              ,iv_account_number
              ,SUBSTR(iv_plan_date, 1, 6)
              ,SUBSTR(iv_plan_date, 7, 2)
              ,iv_period_year
              ,'2'                          -- 日別
              ,lt_sales_plan_amt_edit
              ,iv_plan_date
              ,in_party_id
              ,'4'                          -- 売上計画(複数顧客)
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.user_id
              ,SYSDATE
              ,fnd_global.login_id);
--
    END IF;
--
    RETURN;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END update_rsrc_acct_daily2;
--
  /**********************************************************************************
   * procedure Name   : delete_rsrc_acct_daily
   * Description      : 顧客別売上計画（日別）の削除
   ***********************************************************************************/
  PROCEDURE delete_rsrc_acct_daily(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'delete_rsrc_acct_daily';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_cnt                       NUMBER;
--
  BEGIN
--
    -- 顧客別売上計画テーブルの日別売上計画の存在チェック
    SELECT  COUNT(xasp.account_sales_plan_id)
      INTO  ln_cnt
      FROM  xxcso_account_sales_plans xasp
     WHERE  xasp.base_code      = iv_base_code
       AND  xasp.account_number = iv_account_number
       AND  xasp.year_month     = iv_plan_date
       AND  xasp.month_date_div = '2'   -- 日別
    ;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- 顧客別売上計画テーブルの月間売上計画を更新
      DELETE  xxcso_account_sales_plans xasp
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.year_month     = iv_plan_date
         AND  xasp.month_date_div = '2'   -- 日別
      ;
--
    END IF;
--
    RETURN;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END delete_rsrc_acct_daily;
--
/**********************************************************************************
 * Function Name    : get_party_id
 * Description      : パーティIDの取得
 *                    顧客コードを検索条件として、顧客マスタVIEWより、パーティIDを取得する。
 ***********************************************************************************/
  FUNCTION get_party_id(
    iv_account_number          IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_id';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_pary_id               NUMBER;
--
  BEGIN
--
    SELECT  xcav.party_id
      INTO  ln_pary_id
      FROM  xxcso_cust_accounts_v xcav
     WHERE  xcav.account_number  = iv_account_number
       AND  ROWNUM               = 1;
--
    RETURN ln_pary_id;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END get_party_id;
--
--
  /**********************************************************************************
   * procedure Name   : distrbt_upd_rsrc_acct_daily
   * Description      : 顧客別売上計画日別按分処理＆更新登録処理／売上計画(複数顧客)
   ***********************************************************************************/
  PROCEDURE distrbt_upd_rsrc_acct_daily(
    iv_year_month               IN  VARCHAR2            -- 計画年月
   ,iv_route_number             IN  VARCHAR2            -- ルートNo
   ,iv_sales_plan_month_amt     IN  VARCHAR2            -- 顧客別売上計画月別
   ,iv_base_code                IN  VARCHAR2            -- 拠点コード
   ,iv_account_number           IN  VARCHAR2            -- 顧客コード
   ,iv_party_id                 IN  VARCHAR2            -- パーティID
   ,iv_vist_targrt_div          IN  VARCHAR2            -- 訪問対象区分
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'distrbt_upd_rsrc_acct_daily';
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    ln_sales_plan_month_amt      NUMBER;
    lv_period_year               VARCHAR2(4);
    ln_cnt                       NUMBER  := 0;
    ln_day_on_month              NUMBER;
    ln_visit_daytimes            NUMBER;

    TYPE amp_array IS TABLE OF xxcso_account_sales_plans.sales_plan_day_amt%TYPE;
    la_amp_array amp_array := amp_array();
--
--
  BEGIN
--
    -- 初期化
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER型に変換
    ln_sales_plan_month_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_month_amt, ',', '')
         );
--
    -- 訪問対象区分≠｢1｣対象の場合
    -- 顧客別売上計画月別＝０、NULLの場合
    -- 　顧客別売上計画テーブル（日別）を削除する。
    IF ( NVL(iv_vist_targrt_div, '2') = '2' OR
         NVL(ln_sales_plan_month_amt, 0) = 0 ) THEN
--
        -- 削除
        delete_rsrc_acct_daily(
          iv_base_code
         ,iv_account_number
         ,iv_year_month
        );
--
        RETURN;
    END IF;
--
    -- 日別売上計画配列の初期化
    la_amp_array.extend(31);
--
    -- 按分処理実行
    xxcso_route_common_pkg.distribute_sales_plan(
      iv_year_month             => iv_year_month
     ,it_sales_plan_amt         => ln_sales_plan_month_amt
     ,it_route_number           => iv_route_number
     ,on_day_on_month           => ln_day_on_month
     ,on_visit_daytimes         => ln_visit_daytimes
     ,ot_sales_plan_day_amt_1   => la_amp_array(1)
     ,ot_sales_plan_day_amt_2   => la_amp_array(2)
     ,ot_sales_plan_day_amt_3   => la_amp_array(3)
     ,ot_sales_plan_day_amt_4   => la_amp_array(4)
     ,ot_sales_plan_day_amt_5   => la_amp_array(5)
     ,ot_sales_plan_day_amt_6   => la_amp_array(6)
     ,ot_sales_plan_day_amt_7   => la_amp_array(7)
     ,ot_sales_plan_day_amt_8   => la_amp_array(8)
     ,ot_sales_plan_day_amt_9   => la_amp_array(9)
     ,ot_sales_plan_day_amt_10  => la_amp_array(10)
     ,ot_sales_plan_day_amt_11  => la_amp_array(11)
     ,ot_sales_plan_day_amt_12  => la_amp_array(12)
     ,ot_sales_plan_day_amt_13  => la_amp_array(13)
     ,ot_sales_plan_day_amt_14  => la_amp_array(14)
     ,ot_sales_plan_day_amt_15  => la_amp_array(15)
     ,ot_sales_plan_day_amt_16  => la_amp_array(16)
     ,ot_sales_plan_day_amt_17  => la_amp_array(17)
     ,ot_sales_plan_day_amt_18  => la_amp_array(18)
     ,ot_sales_plan_day_amt_19  => la_amp_array(19)
     ,ot_sales_plan_day_amt_20  => la_amp_array(20)
     ,ot_sales_plan_day_amt_21  => la_amp_array(21)
     ,ot_sales_plan_day_amt_22  => la_amp_array(22)
     ,ot_sales_plan_day_amt_23  => la_amp_array(23)
     ,ot_sales_plan_day_amt_24  => la_amp_array(24)
     ,ot_sales_plan_day_amt_25  => la_amp_array(25)
     ,ot_sales_plan_day_amt_26  => la_amp_array(26)
     ,ot_sales_plan_day_amt_27  => la_amp_array(27)
     ,ot_sales_plan_day_amt_28  => la_amp_array(28)
     ,ot_sales_plan_day_amt_29  => la_amp_array(29)
     ,ot_sales_plan_day_amt_30  => la_amp_array(30)
     ,ot_sales_plan_day_amt_31  => la_amp_array(31)
     ,ov_errbuf                 => ov_errbuf
     ,ov_retcode                => ov_retcode
     ,ov_errmsg                 => ov_errmsg
    );
--
    -- 会計年度取得
    SELECT  TO_CHAR(glp.period_year)
    INTO  lv_period_year
    FROM  gl_sets_of_books  glb  -- 会計帳簿マスタ
         ,gl_periods        glp  -- 会計カレンダテーブル
    WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
     AND  glp.period_set_name              = glb.period_set_name
     AND  TO_CHAR(glp.start_date,'YYYYMM') = iv_year_month
     AND  glp.adjustment_period_flag       = 'N';
--
    -- 顧客別売上計画テーブル（日別）登録更新
    -- 配列の要素数分ループする
    FOR i in 1..la_amp_array.COUNT LOOP
--
    	IF ( i <= ln_day_on_month ) THEN
--
		    update_rsrc_acct_daily2(
		      iv_base_code
		     ,iv_account_number
		     ,iv_year_month || TRIM(TO_CHAR(i, '00'))
		     ,la_amp_array(i)
		     ,TO_NUMBER(iv_party_id)
		     ,lv_period_year
		     ,ov_errbuf
		     ,ov_retcode
		     ,ov_errmsg
		    );
--
    	END IF;
--
    END LOOP;
--
      RETURN;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  固定部 END   ##########################################
  END distrbt_upd_rsrc_acct_daily;
--
END xxcso_rsrc_sales_plans_pkg;
--
/
