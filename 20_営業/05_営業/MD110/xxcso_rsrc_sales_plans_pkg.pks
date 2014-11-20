CREATE OR REPLACE PACKAGE APPS.xxcso_rsrc_sales_plans_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rsrc_sales_plans_pkg(SPEC)
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
 *  get_rsrc_monthly_plan        F    -     営業員計画情報 月間売上計画取得
 *  get_acct_monthly_plan_sum    F    -     営業員計画情報 設定済売上計画の取得
 *  get_rsrc_acct_differ         F    -     営業員計画情報 差額取得
 *  get_acct_daily_plan_sum      F    -     顧客別売上計画（月別）設定済日別計画取得
 *  get_rsrc_acct_daily_differ   F    -     顧客別売上計画（月別）差額取得
 *  update_rsrc_acct_monthly     P    -     顧客別売上計画（月別）の登録更新
 *  update_rsrc_acct_daily       P    -     顧客別売上計画（日別）の登録更新
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
  -- 売上計画トランザクション初期化
  PROCEDURE init_transaction(
    iv_base_code             IN  VARCHAR2
   ,iv_account_number        IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- 売上計画(複数顧客)トランザクション初期化
  PROCEDURE init_transaction_bulk(
    iv_base_code             IN  VARCHAR2
   ,iv_employee_number       IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- トランザクションロック処理
  PROCEDURE process_lock(
    in_trgt_account_sales_plan_id  IN  NUMBER
   ,id_trgt_last_update_date       IN  DATE
   ,in_next_account_sales_plan_id  IN  NUMBER
   ,id_next_last_update_date       IN  DATE
   ,ov_errbuf                      OUT NOCOPY VARCHAR2
   ,ov_retcode                     OUT NOCOPY VARCHAR2
   ,ov_errmsg                      OUT NOCOPY VARCHAR2
  );
--
  -- 営業員月間売上計画取得
  FUNCTION get_rsrc_monthly_plan(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 営業員設定済売上計画取得
  FUNCTION get_acct_monthly_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 営業員月間設定済売上計画差額取得
  FUNCTION get_rsrc_monthly_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 営業員設定済日別計画取得
  FUNCTION get_acct_daily_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 営業員月間設定済日別計画差額取得
  FUNCTION get_rsrc_acct_daily_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 顧客別売上計画（月別）の登録更新
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
  );
--
  -- 顧客別売上計画（日別）の登録更新
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
  );
--
  -- パーティIDの取得
  FUNCTION get_party_id(
    iv_account_number           IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- 顧客別売上計画日別按分処理＆更新登録処理
  PROCEDURE distrbt_upd_rsrc_acct_daily(
    iv_year_month               IN  VARCHAR2
   ,iv_route_number             IN  VARCHAR2
   ,iv_sales_plan_month_amt     IN  VARCHAR2
   ,iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_party_id                 IN  VARCHAR2
   ,iv_vist_targrt_div          IN  VARCHAR2
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  );
--
  -- 顧客別売上計画（日別）の削除
  PROCEDURE delete_rsrc_acct_daily(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
  );
--
  -- 顧客別売上計画（日別）の登録更新２
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
  );
--
END xxcso_rsrc_sales_plans_pkg;
/
