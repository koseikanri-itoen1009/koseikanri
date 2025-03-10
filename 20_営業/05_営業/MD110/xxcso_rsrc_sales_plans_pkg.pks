CREATE OR REPLACE PACKAGE APPS.xxcso_rsrc_sales_plans_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rsrc_sales_plans_pkg(SPEC)
 * Description      : Kâãvæ¤ÊÖ(cÆEcÆÌæj
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  --------------------------- ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------------- ---- ----- --------------------------------------------------
 *  init_transaction             P    -     ãvægUNVú»
 *  init_transaction_bulk        P    -     ãvæ(¡Úq)gUNVú»
 *  get_rsrc_monthly_plan        F    -     cÆõvæîñ Ôãvææ¾
 *  get_acct_monthly_plan_sum    F    -     cÆõvæîñ ÝèÏãvæÌæ¾
 *  get_rsrc_acct_differ         F    -     cÆõvæîñ ·zæ¾
 *  get_acct_daily_plan_sum      F    -     ÚqÊãvæiÊjÝèÏúÊvææ¾
 *  get_rsrc_acct_daily_differ   F    -     ÚqÊãvæiÊj·zæ¾
 *  update_rsrc_acct_monthly     P    -     ÚqÊãvæiÊjÌo^XV
 *  update_rsrc_acct_daily       P    -     ÚqÊãvæiúÊjÌo^XV
 *  get_party_id                 F    -     p[eBIDÌæ¾
 *  distrbt_upd_rsrc_acct_daily  P    -     ÚqÊãvæúÊÂªXVo^
 *  delete_rsrc_acct_daily       P    -     ÚqÊãvæiúÊjÌí
 *  update_rsrc_acct_daily2      P    -     ÚqÊãvæiúÊjÌo^XVQ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Boku           VKì¬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897Î
 *
 *****************************************************************************************/
  -- ãvægUNVú»
  PROCEDURE init_transaction(
    iv_base_code             IN  VARCHAR2
   ,iv_account_number        IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- ãvæ(¡Úq)gUNVú»
  PROCEDURE init_transaction_bulk(
    iv_base_code             IN  VARCHAR2
   ,iv_employee_number       IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- gUNVbN
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
  -- cÆõÔãvææ¾
  FUNCTION get_rsrc_monthly_plan(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- cÆõÝèÏãvææ¾
  FUNCTION get_acct_monthly_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- cÆõÔÝèÏãvæ·zæ¾
  FUNCTION get_rsrc_monthly_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- cÆõÝèÏúÊvææ¾
  FUNCTION get_acct_daily_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- cÆõÔÝèÏúÊvæ·zæ¾
  FUNCTION get_rsrc_acct_daily_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- ÚqÊãvæiÊjÌo^XV
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
  -- ÚqÊãvæiúÊjÌo^XV
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
  -- p[eBIDÌæ¾
  FUNCTION get_party_id(
    iv_account_number           IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- ÚqÊãvæúÊÂªXVo^
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
  -- ÚqÊãvæiúÊjÌí
  PROCEDURE delete_rsrc_acct_daily(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
  );
--
  -- ÚqÊãvæiúÊjÌo^XVQ
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
