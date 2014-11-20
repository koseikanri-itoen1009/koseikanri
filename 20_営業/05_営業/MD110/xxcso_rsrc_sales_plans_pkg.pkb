CREATE OR REPLACE PACKAGE BODY APPS.xxcso_rsrc_sales_plans_pkg
IS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_rsrc_sales_plans_pkg(BODY)
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
 *  process_lock                 P    -     �g�����U�N�V�������b�N
 *  get_rsrc_monthly_plan        F    -     �c�ƈ��v���� ���Ԕ���v��擾
 *  get_acct_monthly_plan_sum    F    -     �c�ƈ��v���� �ݒ�ϔ���v��̎擾
 *  get_rsrc_acct_differ         F    -     �c�ƈ��v���� ���z�擾
 *  get_acct_daily_plan_sum      F    -     �ڋq�ʔ���v��i���ʁj�ݒ�ϓ��ʌv��擾
 *  get_rsrc_acct_daily_differ   F    -     �ڋq�ʔ���v��i���ʁj���z�擾
 *  update_rsrc_acct_monthly     P    -     �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
 *  update_rsrc_acct_daily       P    -     �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
 *  delete_rsrc_acct_daily       P    -     �ڋq�ʔ���v��i���ʁj�̍폜
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_rsrc_sales_plans_pkg';   -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  nowait_except       EXCEPTION;
  PRAGMA EXCEPTION_INIT(nowait_except, -54);
--
  /**********************************************************************************
   * Function Name    : init_transaction
   * Description      : ����v��g�����U�N�V����������
   ***********************************************************************************/
  -- ����v��g�����U�N�V����������
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'init_transaction';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
  BEGIN
--
    -- ������
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END init_transaction;
--
  /**********************************************************************************
   * Function Name    : init_transaction_bulk
   * Description      : ����v��(�����ڋq)�g�����U�N�V����������
   ***********************************************************************************/
  -- ����v��(�����ڋq)�g�����U�N�V����������
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'init_transaction_bulk';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_count                     NUMBER;
    ld_year_month                DATE;

  BEGIN
--
    -- ������
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
--  �c�ƈ��S���ڋqVIEW���A�]�ƈ��ԍ��ɕR�t���ڋq�R�[�h���擾���A
--  ���[�N�e�[�u���փ��R�[�h�ǉ�����B
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END init_transaction_bulk;
--
   /**********************************************************************************
   * Function Name    : process_lock
   * Description      : �g�����U�N�V�������b�N����
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'process_lock';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ld_trgt_last_update_date     DATE;
    ld_next_last_update_date     DATE;
    lb_exception_flag            BOOLEAN;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
    lb_exception_flag := FALSE;
--
    BEGIN
--
      -- ����
      IF ( in_trgt_account_sales_plan_id IS NOT NULL ) THEN
	      SELECT  xasp.last_update_date
	        INTO  ld_trgt_last_update_date
	        FROM  xxcso_account_sales_plans  xasp
	       WHERE  xasp.account_sales_plan_id = in_trgt_account_sales_plan_id
	         FOR UPDATE NOWAIT
	      ;
	  END IF;
--
      -- ����
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
      -- *** NO_DATA_FOUND�n���h�� ***
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
      -- ����
      if ( in_trgt_account_sales_plan_id IS NOT NULL AND
           id_trgt_last_update_date <> ld_trgt_last_update_date ) THEN
--
        ov_retcode := xxcso_common_pkg.gv_status_error;
        ov_errmsg  := 'APP-XXCSO1-00003';
--
      END IF;
--
      -- ����
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END process_lock;
--
  /**********************************************************************************
   * Function Name    : get_rsrc_monthly_plan
   * Description      : �c�ƈ��v���� ���Ԕ���v��擾
   *                    �c�ƈ��ʌ��ʌv��e�[�u���̔���v��J���敪�ɂ��
   *                    �ڕW����i�c�ƈ��v�F�v�j�܂��́A��{����i�c�ƈ��v�F�v�j���擾
   ***********************************************************************************/
  FUNCTION get_rsrc_monthly_plan(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_monthly_plan';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_plan_amt                  NUMBER;
--
  BEGIN
--
    SELECT
            (CASE
               WHEN ( xdmp.sales_plan_rel_div = '1' ) THEN  -- �ڕW����v��
                 xspmp.tgt_sales_prsn_total_amt             -- �ڕW����i�c�ƈ��v�F�v�j
               ELSE                                         -- ��{����v��
                 xspmp.bsc_sls_prsn_total_amt               -- ��{����i�c�ƈ��v�F�v�j
             END
            ) AS plan_amt
      INTO  ln_plan_amt
      FROM  xxcso_sls_prsn_mnthly_plns xspmp,      -- �c�ƈ��ʌ��ʌv��e�[�u��
            xxcso_dept_monthly_plans xdmp          -- ���_�ʌ��ʌv��e�[�u��
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_rsrc_monthly_plan;
--
--
--
/**********************************************************************************
 * Function Name    : get_acct_monthly_plan_sum
 * Description      : �c�ƈ��v���� �ݒ�ϔ���v��̎擾
 *                    �i�c�ƈ��́j�ڋq�ʔ���v��e�[�u���̌��ʔ���v����W�v
 ***********************************************************************************/
  FUNCTION get_acct_monthly_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_acct_monthly_plan_sum';
--
    -- ===============================
    -- ���[�J���ϐ�
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
       AND  xasp.month_date_div                        = '1'  -- ���ʌv��
       AND  xrcv.employee_number                       = iv_employee_number
       AND  TRUNC(xrcv.start_date_active, 'DD')       <= ld_plan_date
       AND  NVL(xrcv.end_date_active, ld_plan_date)   >= ld_plan_date;
--
    RETURN TO_CHAR(ln_plan_amt, 'FM999G999G990');
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_acct_monthly_plan_sum;
--
  /**********************************************************************************
   * Function Name    : get_rsrc_acct_differ
   * Description      : �c�ƈ��v���� ���z�擾
   *                    ���Ԕ���v��|�ݒ�ϔ���v��
   ***********************************************************************************/
  FUNCTION get_rsrc_monthly_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_employee_number          IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_monthly_differ';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_plan_month                NUMBER;
    ln_plan_daily_sum            NUMBER;
  BEGIN
    -- ���Ԕ���v����擾
    ln_plan_month := 
      TO_NUMBER(
        get_rsrc_monthly_plan(
          iv_base_code, iv_employee_number, iv_year_month), 'FM999G999G990');
--
    -- �ݒ�ϔ���v����擾
    ln_plan_daily_sum := 
      TO_NUMBER(
        get_acct_monthly_plan_sum(
          iv_base_code, iv_employee_number, iv_year_month), 'FM999G999G990');
--
    -- ���Ԕ���v�恄�O�i��NULL�j�̏ꍇ�A���z���v�Z����B
    -- �ݒ�ϔ���v�恁NULL�̏ꍇ�A�O�Ƃ��Čv�Z����B
    IF ( NVL(ln_plan_month, 0) > 0 ) THEN
      RETURN TO_CHAR(ln_plan_month - NVL(ln_plan_daily_sum, 0), 'FM999G999G990');
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_rsrc_monthly_differ;
--
--
--
  /**********************************************************************************
   * Function Name    : get_acct_daily_plan_sum
   * Description      : �ڋq�ʔ���v��i���ʁj�ݒ�ϓ��ʌv��擾
   *                    �ڋq�ʔ���v��e�[�u���̓��ʔ���v����W�v
   ***********************************************************************************/
  FUNCTION get_acct_daily_plan_sum(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_acct_daily_plan_sum';
--
    -- ===============================
    -- ���[�J���ϐ�
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
       AND  xasp.month_date_div  = '2';  -- ���ʌv��
--
    RETURN TO_CHAR(ln_plan_amt, 'FM999G999G990');
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_acct_daily_plan_sum;
--
--
--
  /**********************************************************************************
   * Function Name    : get_rsrc_acct_daily_differ
   * Description      : �ڋq�ʔ���v��i���ʁj���z�擾
   *                    ���z�����Ԕ���v��|�ݒ�ϓ��ʌv��
   ***********************************************************************************/
  FUNCTION get_rsrc_acct_daily_differ(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_year_month               IN  VARCHAR2
  ) RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_rsrc_acct_daily_differ';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_plan_month                NUMBER;
    ln_plan_daily_sum            NUMBER;
--
  BEGIN
--
    -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v����擾
    BEGIN
      SELECT  xasp.sales_plan_month_amt
        INTO  ln_plan_month
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.year_month     = iv_year_month
         AND  xasp.month_date_div = '1'  -- ���ʌv��
         AND  ROWNUM              = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_plan_month := 0;
    END;
--
    -- �ݒ�ϓ��ʌv����擾
    ln_plan_daily_sum := 
      TO_NUMBER(
        get_acct_daily_plan_sum(
          iv_base_code, iv_account_number, iv_year_month), 'FM999G999G990');
--
    -- ���Ԕ���v�恄�O�i��NULL�j�̏ꍇ�A���z���v�Z����B
    -- �ݒ�ϓ��ʌv�恁NULL�̏ꍇ�A�O�Ƃ��Čv�Z����B
    IF ( NVL(ln_plan_month, 0) > 0 ) THEN
      RETURN TO_CHAR(ln_plan_month - NVL(ln_plan_daily_sum, 0), 'FM999G999G990');
    ELSE
      RETURN NULL;
    END IF;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_rsrc_acct_daily_differ;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_monthly
   * Description      : �ڋq�ʔ���v��i���ʁj�̓o�^�X�V
   *                    �K��E����v���ʁ^����v��(�����ڋq)
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_monthly';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_sales_plan_month_amt      NUMBER;
    lv_period_year               VARCHAR2(4);
    ln_pary_id                   NUMBER;
    ln_cnt                       NUMBER  := 0;
    lv_update_func_div           VARCHAR2(1) := '3';     -- �K��E����v����
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER�^�ɕϊ�
    ln_sales_plan_month_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_month_amt, ',', '')
         );
--
    -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v��̑��݃`�F�b�N
    IF ( in_account_sales_plan_id IS NOT NULL ) THEN
      SELECT  COUNT(xasp.account_sales_plan_id)
        INTO  ln_cnt
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
    END IF;
--
    -- �X�V�@�\�敪
    IF ( NVL(iv_distribute_flg, '0') = '1'  ) THEN
      lv_update_func_div := '4';  -- ����v��(�����ڋq)
    END IF;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v����X�V
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
      -- ��v�N�x�擾
      SELECT  TO_CHAR(glp.period_year)
        INTO  lv_period_year
        FROM  gl_sets_of_books  glb  -- ��v����}�X�^
             ,gl_periods        glp  -- ��v�J�����_�e�[�u��
       WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
         AND  glp.period_set_name              = glb.period_set_name
         AND  TO_CHAR(glp.start_date,'YYYYMM') = iv_year_month
         AND  glp.adjustment_period_flag       = 'N';
--
      -- �p�[�e�BID�擾
      ln_pary_id := get_party_id(iv_account_number);
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v���o�^
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
              ,'1'                          -- ����
              ,ln_sales_plan_month_amt
              ,iv_year_month || '99'
              ,ln_pary_id
              ,lv_update_func_div           -- �X�V�@�\�敪
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END update_rsrc_acct_monthly;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_daily
   * Description      : �ڋq�ʔ���v��i���ʁj�̓o�^�X�V�^�K��E����v����
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_daily';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_sales_plan_day_amt        NUMBER;
    lv_period_year               VARCHAR2(4);
    ln_cnt                       NUMBER;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER�^�ɕϊ�
    ln_sales_plan_day_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_day_amt, ',', '')
         );
--
    -- �ڋq�ʔ���v��e�[�u���̓��ʔ���v��̑��݃`�F�b�N
    IF ( in_account_sales_plan_id IS NOT NULL ) THEN
      SELECT  COUNT(xasp.account_sales_plan_id)
        INTO  ln_cnt
        FROM  xxcso_account_sales_plans xasp
       WHERE  xasp.account_sales_plan_id = in_account_sales_plan_id;
    END IF;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v����X�V
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
      -- ��v�N�x�擾
      SELECT  TO_CHAR(glp.period_year)
        INTO  lv_period_year
        FROM  gl_sets_of_books  glb  -- ��v����}�X�^
             ,gl_periods        glp  -- ��v�J�����_�e�[�u��
       WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
         AND  glp.period_set_name              = glb.period_set_name
         AND  TO_CHAR(glp.start_date,'YYYYMM') = SUBSTR(iv_plan_date, 1, 6)
         AND  glp.adjustment_period_flag       = 'N';
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v���o�^
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
              ,'2'                          -- ����
              ,ln_sales_plan_day_amt
              ,iv_plan_date
              ,in_party_id
              ,'3'                          -- �K�┄��v��
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END update_rsrc_acct_daily;
--
  /**********************************************************************************
   * procedure Name   : update_rsrc_acct_daily2
   * Description      : �ڋq�ʔ���v��i���ʁj�̓o�^�X�V�^����v��(�����ڋq)
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
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'update_rsrc_acct_daily2';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_cnt                       NUMBER;
    lt_sales_plan_amt_edit       xxcso_account_sales_plans.sales_plan_day_amt%TYPE := NULL;
--
  BEGIN
--
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- ���ʔ���v�恁0�̏ꍇ�ANULL�N���A
    IF ( it_sales_plan_day_amt > 0 ) THEN
      lt_sales_plan_amt_edit := it_sales_plan_day_amt;
    END IF;
--
    -- �ڋq�ʔ���v��e�[�u���̓��ʔ���v��̑��݃`�F�b�N
    SELECT  COUNT(xasp.account_sales_plan_id)
      INTO  ln_cnt
      FROM  xxcso_account_sales_plans xasp
     WHERE  xasp.base_code      = iv_base_code
       AND  xasp.account_number = iv_account_number
       AND  xasp.plan_date      = iv_plan_date
       AND  xasp.month_date_div = '2'   -- ����
    ;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- �ڋq�ʔ���v��e�[�u���̓��ʔ���v����X�V
      UPDATE  xxcso_account_sales_plans xasp
         SET  xasp.sales_plan_day_amt   = lt_sales_plan_amt_edit
             ,xasp.update_func_div      = '4'
             ,xasp.last_updated_by      = fnd_global.user_id
             ,xasp.last_update_date     = SYSDATE
             ,xasp.last_update_login    = fnd_global.login_id
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.plan_date      = iv_plan_date
         AND  xasp.month_date_div = '2'   -- ����
      ;
--
    ELSE
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v���o�^
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
              ,'2'                          -- ����
              ,lt_sales_plan_amt_edit
              ,iv_plan_date
              ,in_party_id
              ,'4'                          -- ����v��(�����ڋq)
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END update_rsrc_acct_daily2;
--
  /**********************************************************************************
   * procedure Name   : delete_rsrc_acct_daily
   * Description      : �ڋq�ʔ���v��i���ʁj�̍폜
   ***********************************************************************************/
  PROCEDURE delete_rsrc_acct_daily(
    iv_base_code                IN  VARCHAR2
   ,iv_account_number           IN  VARCHAR2
   ,iv_plan_date                IN  VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'delete_rsrc_acct_daily';
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    ln_cnt                       NUMBER;
--
  BEGIN
--
    -- �ڋq�ʔ���v��e�[�u���̓��ʔ���v��̑��݃`�F�b�N
    SELECT  COUNT(xasp.account_sales_plan_id)
      INTO  ln_cnt
      FROM  xxcso_account_sales_plans xasp
     WHERE  xasp.base_code      = iv_base_code
       AND  xasp.account_number = iv_account_number
       AND  xasp.year_month     = iv_plan_date
       AND  xasp.month_date_div = '2'   -- ����
    ;
--
    IF ( ln_cnt > 0 ) THEN
--
      -- �ڋq�ʔ���v��e�[�u���̌��Ԕ���v����X�V
      DELETE  xxcso_account_sales_plans xasp
       WHERE  xasp.base_code      = iv_base_code
         AND  xasp.account_number = iv_account_number
         AND  xasp.year_month     = iv_plan_date
         AND  xasp.month_date_div = '2'   -- ����
      ;
--
    END IF;
--
    RETURN;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END delete_rsrc_acct_daily;
--
/**********************************************************************************
 * Function Name    : get_party_id
 * Description      : �p�[�e�BID�̎擾
 *                    �ڋq�R�[�h�����������Ƃ��āA�ڋq�}�X�^VIEW���A�p�[�e�BID���擾����B
 ***********************************************************************************/
  FUNCTION get_party_id(
    iv_account_number          IN  VARCHAR2
  ) RETURN NUMBER
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'get_party_id';
--
    -- ===============================
    -- ���[�J���ϐ�
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END get_party_id;
--
--
  /**********************************************************************************
   * procedure Name   : distrbt_upd_rsrc_acct_daily
   * Description      : �ڋq�ʔ���v����ʈ��������X�V�o�^�����^����v��(�����ڋq)
   ***********************************************************************************/
  PROCEDURE distrbt_upd_rsrc_acct_daily(
    iv_year_month               IN  VARCHAR2            -- �v��N��
   ,iv_route_number             IN  VARCHAR2            -- ���[�gNo
   ,iv_sales_plan_month_amt     IN  VARCHAR2            -- �ڋq�ʔ���v�挎��
   ,iv_base_code                IN  VARCHAR2            -- ���_�R�[�h
   ,iv_account_number           IN  VARCHAR2            -- �ڋq�R�[�h
   ,iv_party_id                 IN  VARCHAR2            -- �p�[�e�BID
   ,iv_vist_targrt_div          IN  VARCHAR2            -- �K��Ώۋ敪
   ,ov_errbuf                   OUT NOCOPY VARCHAR2
   ,ov_retcode                  OUT NOCOPY VARCHAR2
   ,ov_errmsg                   OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                  CONSTANT VARCHAR2(100)   := 'distrbt_upd_rsrc_acct_daily';
--
    -- ===============================
    -- ���[�J���ϐ�
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
    -- ������
    ov_retcode := xxcso_common_pkg.gv_status_normal;
    ov_errbuf  := NULL;
    ov_errmsg  := NULL;
--
    -- NUMBER�^�ɕϊ�
    ln_sales_plan_month_amt 
      := TO_NUMBER(
           REPLACE(iv_sales_plan_month_amt, ',', '')
         );
--
    -- �K��Ώۋ敪���1��Ώۂ̏ꍇ
    -- �ڋq�ʔ���v�挎�ʁ��O�ANULL�̏ꍇ
    -- �@�ڋq�ʔ���v��e�[�u���i���ʁj���폜����B
    IF ( NVL(iv_vist_targrt_div, '2') = '2' OR
         NVL(ln_sales_plan_month_amt, 0) = 0 ) THEN
--
        -- �폜
        delete_rsrc_acct_daily(
          iv_base_code
         ,iv_account_number
         ,iv_year_month
        );
--
        RETURN;
    END IF;
--
    -- ���ʔ���v��z��̏�����
    la_amp_array.extend(31);
--
    -- ���������s
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
    -- ��v�N�x�擾
    SELECT  TO_CHAR(glp.period_year)
    INTO  lv_period_year
    FROM  gl_sets_of_books  glb  -- ��v����}�X�^
         ,gl_periods        glp  -- ��v�J�����_�e�[�u��
    WHERE  glb.set_of_books_id              = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')  -- '1002' 
     AND  glp.period_set_name              = glb.period_set_name
     AND  TO_CHAR(glp.start_date,'YYYYMM') = iv_year_month
     AND  glp.adjustment_period_flag       = 'N';
--
    -- �ڋq�ʔ���v��e�[�u���i���ʁj�o�^�X�V
    -- �z��̗v�f�������[�v����
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt(gv_pkg_name, cv_prg_name);
--
--#####################################  �Œ蕔 END   ##########################################
  END distrbt_upd_rsrc_acct_daily;
--
END xxcso_rsrc_sales_plans_pkg;
--
/
