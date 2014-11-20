CREATE OR REPLACE PACKAGE APPS.xxcso_rsrc_sales_plans_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rsrc_sales_plans_pkg(SPEC)
 * Description      : �K�┄��v�拤�ʊ֐�(�c�ƁE�c�Ɨ̈�j
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  --------------------------- ---- ----- --------------------------------------------------
 *   Name                       Type  Ret   Description
 *  --------------------------- ---- ----- --------------------------------------------------
 *  init_transaction             P    -     ����v��g�����U�N�V����������
 *  init_transaction_bulk        P    -     ����v��(�����ڋq)�g�����U�N�V����������
 *  get_rsrc_monthly_plan        F    -     �c�ƈ��v���� ���Ԕ���v��擾
 *  get_acct_monthly_plan_sum    F    -     �c�ƈ��v���� �ݒ�ϔ���v��̎擾
 *  get_rsrc_acct_differ         F    -     �c�ƈ��v���� ���z�擾
 *  get_acct_daily_plan_sum      F    -     �ڋq�ʔ���v��i���ʁj�ݒ�ϓ��ʌv��擾
 *  get_rsrc_acct_daily_differ   F    -     �ڋq�ʔ���v��i���ʁj���z�擾
 *  update_rsrc_acct_monthly     P    -     �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
 *  update_rsrc_acct_daily       P    -     �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
 *  get_party_id                 F    -     �p�[�e�BID�̎擾
 *  distrbt_upd_rsrc_acct_daily  P    -     �ڋq�ʔ���v����ʈ��������X�V�o�^����
 *  delete_rsrc_acct_daily       P    -     �ڋq�ʔ���v��i���ʁj�̍폜
 *  update_rsrc_acct_daily2      P    -     �ڋq�ʔ���v��i���ʁj�̓o�^�X�V�Q
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   K.Boku           �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
  -- ����v��g�����U�N�V����������
  PROCEDURE init_transaction(
    iv_base_code             IN  VARCHAR2
   ,iv_account_number        IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- ����v��(�����ڋq)�g�����U�N�V����������
  PROCEDURE init_transaction_bulk(
    iv_base_code             IN  VARCHAR2
   ,iv_employee_number       IN  VARCHAR2
   ,iv_year_month            IN  VARCHAR2
   ,ov_errbuf                OUT NOCOPY VARCHAR2
   ,ov_retcode               OUT NOCOPY VARCHAR2
   ,ov_errmsg                OUT NOCOPY VARCHAR2
  );
--
  -- �g�����U�N�V�������b�N����
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
  -- �c�ƈ����Ԕ���v��擾
  FUNCTION get_rsrc_monthly_plan(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �c�ƈ��ݒ�ϔ���v��擾
  FUNCTION get_acct_monthly_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �c�ƈ����Ԑݒ�ϔ���v�捷�z�擾
  FUNCTION get_rsrc_monthly_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �c�ƈ��ݒ�ϓ��ʌv��擾
  FUNCTION get_acct_daily_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �c�ƈ����Ԑݒ�ϓ��ʌv�捷�z�擾
  FUNCTION get_rsrc_acct_daily_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
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
  -- �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
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
  -- �p�[�e�BID�̎擾
  FUNCTION get_party_id(
    iv_account_number           IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- �ڋq�ʔ���v����ʈ��������X�V�o�^����
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
  -- �ڋq�ʔ���v��i���ʁj�̍폜
  PROCEDURE delete_rsrc_acct_daily(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
  );
--
  -- �ڋq�ʔ���v��i���ʁj�̓o�^�X�V�Q
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
